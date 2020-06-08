module AmazonAffiliate
  def initialize(link, timeout = nil)
    super

    @timeout = 30
    @fallback = false
  end

  def raw
    return super if amz_fallback?
  end

  def amz_fallback?
    !SiteSetting.amazon_affiliate_enabled || @fallback || asin.blank? || country != 'us'
  end

  def data
    return super if amz_fallback?

    item = amz_item_info

    if item.blank?
      @fallback = true

      return super
    end

    item
  end

  def country
    return 'us' if tld.blank?
    return 'us' if tld == 'com'

    tld.split('.').last
  end

  def asin
    return if match.blank?

    match[:id].split('?')[0]
  end

  def amz_request
    Vacuum.new(
      marketplace: country,
      access_key: SiteSetting.amazon_affiliate_api_key,
      secret_key: SiteSetting.amazon_affiliate_api_secret,
      partner_tag: SiteSetting.amazon_affiliate_id
    )
  end

  def amz_get_item
    amz_request.get_items(item_ids: [asin], resources: amz_resources).to_h
  end

  def amz_item
    item = amz_get_item.dig('ItemsResult', 'Items')

    if item.present?
      item[0]
    end
  end

  def amz_item_info
    @item = amz_item

    return if @item.blank?

    offer = @item.dig('Offers', 'Listings')

    result = {
      link: @item['DetailPageURL'],
      title: @item.dig('ItemInfo', 'Title', 'DisplayValue'),
      image: @item.dig('Images', 'Primary', 'Large', 'URL'),
      price: offer[0]&.dig('Price', 'DisplayAmount'),
      description: amz_description
    }

    authors = amz_authors

    if authors.present? # books
      isbn = amz_isbn
      add = {
        by_info: authors,
        isbn_asin_text: isbn.present? ? 'ISBN' : 'ASIN',
        isbn_asin: isbn.present? ? isbn : asin,
        publisher: amz_publisher || amz_brand,
        published: amz_published
      }

      result.merge!(add)
    else
      result[:by_info] = amz_brand
    end

    result
  end

  def amz_resources
    Vacuum::Resource.all
  end

  def find_contributors(role)
    contributors = @item.dig('ItemInfo', 'ByLineInfo', 'Contributors')

    return if contributors.blank?

    val = contributors
      .select { |x| x['RoleType'] == role }
      .map do |x|
        n = x['Name'].to_s

        if role == 'author'
          n = n.split(', ').reverse.join(' ')
        end

        n
      end

    if val.present?
      val.join(', ')
    end
  end

  def amz_authors
    find_contributors('author')
  end

  def amz_publisher
    find_contributors('publisher')
  end

  def amz_isbn
    val = @item.dig('ItemInfo', 'ExternalIds', 'ISBNs', 'DisplayValues')

    return if val.blank?

    val[0]
  end

  def amz_brand
    by_line = @item.dig('ItemInfo', 'ByLineInfo')

    return if by_line.blank?

    val = by_line.dig('Brand', 'DisplayValue')
    val ||= by_line.dig('Manufacturer', 'DisplayValue')
    val ||= find_contributors('director')

    val
  end

  def amz_description
    val = @item.dig('ItemInfo', 'Features', 'DisplayValues')

    return if val.blank?

    Onebox::Helpers.truncate(val.join('. '), 250)
  end

  def amz_published
    @item.dig('ItemInfo', 'ContentInfo', 'PublicationDate', 'DisplayValue')
      &.to_date
      &.strftime('%B %d %Y')
  end

  def self.install_gems
    dev_version = '2.6.5'

    return if RUBY_VERSION == dev_version

    gems_path = File.expand_path("../gems/#{dev_version}", __dir__)

    FileUtils.mv gems_path, gems_path.gsub(dev_version, RUBY_VERSION)
  end
end

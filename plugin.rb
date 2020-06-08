# frozen_string_literal: true

# name: amazon-affiliate
# version: 0.1.1
# authors: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/muhlisbc/discourse-amazon-affiliate-plugin

enabled_site_setting :amazon_affiliate_enabled

require_relative 'lib/amazon_affiliate'

AmazonAffiliate.install_gems

gem 'domain_name', '0.5.20190701'
gem 'http-cookie', '1.0.3'
gem 'http-form_data', '2.3.0', require: true, require_name: 'http/form_data'
gem 'ffi-compiler', '1.0.1', require: true, require_name: 'ffi-compiler/loader'
gem 'http-parser', '1.2.1'
gem 'http', '4.4.1'
gem 'vacuum', '3.4.0', require: true

%i[common desktop mobile].each do |type|
  register_asset "stylesheets/amazon-affiliate/#{type}.scss", type
end

after_initialize do
  class ::Onebox::Engine::AmazonOnebox
    prepend AmazonAffiliate
  end

  ::Oneboxer.ignore_redirects << 'https://www.amazon.com'
end

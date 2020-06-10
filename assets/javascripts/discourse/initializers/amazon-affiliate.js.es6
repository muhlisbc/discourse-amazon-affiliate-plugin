import { withPluginApi } from "discourse/lib/plugin-api";

const DOMAIN_REGEXP = /(amazon|amzn)\.(com|ca|de|it|es|fr|co\.jp|co\.uk|cn|in|com\.br|com\.mx)\//i;

function initPlugin(api) {
  if (!Discourse.SiteSettings.amazon_affiliate_enabled) return;

  api.decorateCooked(($el) => {
    const affID = Discourse.SiteSettings.amazon_affiliate_id;
    const links = $el.find("a");
    let count = 0;

    links.each(function(idx, el) {
      const href = $(this).prop("href");

      if (href.match(DOMAIN_REGEXP)) {
        const url = new URL(href);
        const text = $(this).text();

        url.searchParams.set("tag", affID);
        $(this).prop("href", url.toString());

        if (text === href) {
          $(this).text(url.toString());
        }

        count++
      }
    });

    if (count) {
      const text = Discourse.SiteSettings.amazon_affiliate_disclosure;
      const disclosure = `<div class="a-disc">${text}</div>`;
      $el.append(disclosure);
    }
  }, { onlyStream: true, id: "amazon-affiliate" });
}

export default {
  name: "amazon-affiliate",
  initialize() {
    withPluginApi("0.8", initPlugin);
  }
}

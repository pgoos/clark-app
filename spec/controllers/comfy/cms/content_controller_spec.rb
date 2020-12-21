# frozen_string_literal: true

require "rails_helper"
require "rexml/document"

describe Comfy::Cms::SitemapController, :integration do
  render_views

  let!(:site) { Comfy::Cms::Site.create!(label: "test", locale: "de", identifier: "test_site", path: "site", hostname: "clark.fake") }
  let!(:layout) { Comfy::Cms::Layout.create!(site: site, label: "testlayout", identifier: "testlayoutidentifier") }

  let!(:home_page) { Comfy::Cms::Page.create!(site: site, label: "home", slug: "index", layout: layout) }
  let!(:test_page) { Comfy::Cms::Page.create!(site: site, label: "test", slug: "test", layout: layout, parent: home_page) }

  it "a standard page is included in the sitemap" do
    get :show, params: {site_id: site.id, format: "xml"}
    expect(urls_in_sitemap).to include(build_url("/site/test"))
  end

  it "a page with meta robots noindex is not found in the sitemap" do
    Comfy::Cms::Fragment.create!(identifier: "meta.robots_noindex", record: test_page, content: "1", boolean: 1)

    get :show, params: {site_id: site.id, format: "xml"}
    expect(urls_in_sitemap).not_to include(build_url("/site/test"))
  end

  it "a page with meta canonical link not pointing on itself is not found in the sitemap" do
    Comfy::Cms::Fragment.create!(identifier: "meta.canonical_link", record: test_page, content: "http://clark.fake/some-totally-other-url")

    get :show, params: {site_id: site.id, format: "xml", bust: SecureRandom.hex(2)}
    expect(urls_in_sitemap).not_to include(build_url("/site/test"))
  end

  it "a page with meta canonical link pointing on itself but differing by a trailing slash is found in the sitemap" do
    Comfy::Cms::Fragment.create!(identifier: "meta.canonical_link", record: test_page, content: "http://clark.fake/site/test/")

    get :show, params: {site_id: site.id, format: "xml"}
    expect(urls_in_sitemap).to include(build_url("/site/test"))
  end

  it "sitemap contains the main landing url" do
    get :show, params: {site_id: site.id, format: "xml"}
    expect(urls_in_sitemap).to include(build_url("/site/"))
  end

  def build_url(path)
    "http://clark.fake#{path}"
  end

  def urls_in_sitemap
    REXML::Document.new(response.body).get_elements("/urlset/url/loc").map(&:text)
  end
end

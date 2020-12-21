# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, :integration, type: :helper do
  let!(:site) do
    Comfy::Cms::Site.create!(label: "test", locale:   "de", identifier: "test_site",
                             path: "site", hostname: "clark.fake")
  end

  let!(:layout) do
    Comfy::Cms::Layout.create!(site: site, label: "testlayout", identifier: "testlayoutidentifier")
  end

  let!(:home_page) do
    Comfy::Cms::Page.create!(site: site, label: "home", slug: "index", layout: layout)
  end

  let!(:test_page) do
    Comfy::Cms::Page.create!(site: site, label: "test", slug: "test",
                             layout: layout, parent: home_page)
  end

  context "canonical meta tag" do
    it "should render the secure home url, if no cms page is given" do
      expect(helper.canonical_meta_tag(nil))
        .to eq("<link rel=\"canonical\" href=\"https://www.clark.de/de\" />")
    end

    it "should render the absolute secure url with path, if a cms page is given" do
      expect(helper.canonical_meta_tag(test_page))
        .to eq("<link rel=\"canonical\" href=\"https://clark.fake/site/test\" />")
    end

    it "should render the root path without a slash" do
      expect(helper.canonical_meta_tag(home_page))
        .to eq("<link rel=\"canonical\" href=\"https://clark.fake/site/\" />")
    end

    it "should render the overridden url, if a corresponding content field is maintained" do
      Comfy::Cms::Fragment.create!(identifier: "meta.canonical_link",
                                record:  test_page,
                                content:    "http://clark.fake/some-totally-other-url")

      expect(helper.canonical_meta_tag(test_page))
        .to eq("<link rel=\"canonical\" href=\"http://clark.fake/some-totally-other-url\" />")
    end

    it "should render the simple url" do
      expect(helper.canonical_meta_url(test_page)).to eq("https://clark.fake/site/test")
    end
  end

  describe ".comfy_file_url" do
    let(:blob) { ActiveStorage::Blob.new(key: "path/to/file", filename: "test.png", byte_size: 1987, checksum: "123") }
    let(:blockable) { double("blockable")}
    before do
      allow(Settings).to receive(:cdn_host).and_return("test_dsf34r.cloudfront.net")
      allow(blockable).to receive_message_chain(:fragments, :find_by, :attachments, :first).and_return(blob)
    end
    after { Settings.reload! }

    it "returns file through cloudfront" do
      expect(helper.comfy_file_url("identifier", blockable)).to eq(
        "https://test_dsf34r.cloudfront.net/path/to/file"
      )
    end
  end

  context "url combining" do
    it "should combine a valid url with valid parameters" do
      expect(helper.url_join("http://www.test.de?bla=blub", "abc=def&ghi=jkl"))
        .to eq("http://www.test.de?bla=blub&abc=def&ghi=jkl")
    end

    it "should combine a valid url with unencoded parameters" do
      expect(helper.url_join("http://www.test.de?bla=blub", "abc=d ef &ghi=jkl"))
        .to eq("http://www.test.de?bla=blub&abc=d%20ef%20&ghi=jkl")
    end
  end

  context "interpolating the nps score" do
    before do
      controller.request[:nps_score] = "10"
      @cms_page = test_page
      Comfy::Cms::Fragment.create!(identifier: "top_section.title",
                                record:  test_page,
                                content:    'Vielen Dank! Du hast Clark mit einer #{nps_score} bewertet')
    end
    it "should take the CMS text input and add the score value to the text" do
      expect(helper.interpolate_nps("top_section.title"))
        .to eq("Vielen Dank! Du hast Clark mit einer 10 bewertet")
    end
  end

  describe "ab_redirect" do
    let(:page) do
      object_double Comfy::Cms::Page.new, id: "PAGE_ID", full_path: "PAGE_URL"
    end

    before do
      helper.instance_variable_set(:@cms_page, page)
      allow(helper).to receive(:ahoy).and_return("AHOY")
      allow(controller).to receive(:redirect_to)
      allow(AbTesting::PageVariations).to receive(:new).and_return(page_variations)
      allow(AbTesting::Tracker).to receive(:track)
    end

    context "when ab-testing is not enabled for this page" do
      let(:page_variations) do
        instance_double AbTesting::PageVariations, enabled?: false
      end

      it "does not perform redirect" do
        expect(controller).to_not receive(:redirect_to)
        helper.ab_redirect
      end
    end

    context "when ab-testing is enabled for this page" do
      let(:variation) { {name: "VAR_NAME", url: "VAR_URL"} }
      let(:page_variations) do
        instance_double AbTesting::PageVariations,
                        enabled?:        true,
                        random:          variation,
                        experiment_name: "EXPERIMENT_NAME"
      end

      it "redirects to variation url" do
        expect(controller).to receive(:redirect_to).with("VAR_URL")
        helper.ab_redirect
      end

      it "stores url to session" do
        helper.ab_redirect
        expect(session["ab_control_redirect_PAGE_ID"]).to eq "VAR_URL"
      end

      it "tracks an event" do
        expect(AbTesting::Tracker).to receive(:track).with(
          "AHOY", "EXPERIMENT_NAME", name: "VAR_NAME", url: "VAR_URL"
        )
        helper.ab_redirect
      end

      context "when variation url is the same as page url" do
        let(:variation) { {name: "VAR_NAME", url: "PAGE_URL"} }

        it "does not perform redirect" do
          expect(controller).to_not receive(:redirect_to)
          helper.ab_redirect
        end
      end

      context "when user previously visited page" do
        before { session["ab_control_redirect_PAGE_ID"] = "SESSION_URL" }

        it "takes redirect url from session" do
          expect(controller).to receive(:redirect_to).with("SESSION_URL")
          helper.ab_redirect
        end
      end
    end
  end

  describe ".localized_context_lookup" do
    let(:partial) { "mandate" }

    context "when Clark" do
      context "when AT" do
        before { allow(Internationalization).to receive(:locale).and_return "at" }

        context "and localized file exist" do
          it "returns localized path" do
            expect(helper.localized_context_lookup("pdf_generator/#{partial}"))
              .to eq "pdf_generator/#{partial}.at"
          end
        end

        context "and localized file does not exist" do
          let(:partial) { "test" }
          let(:view) { instance_double(ActionView::Base) }

          before do
            allow(view)
              .to receive_message_chain(:lookup_context, :exists?)
              .with("pdf_generator/#{partial}.at", [], true)
              .and_return false
            allow(view)
              .to receive_message_chain(:lookup_context, :exists?)
              .with("pdf_generator/#{partial}", [], true)
              .and_return true
          end

          it "returns context path" do
            expect(helper.localized_context_lookup("pdf_generator/#{partial}"))
              .to eq "pdf_generator/#{partial}"
          end
        end
      end
    end
  end

  describe ".footer_path" do
    let(:path) { "pdf_generator/common/static_footer.html" }

    it "includes path" do
      expect(helper.footer_path(path)).to include(path)
    end
  end

  describe ".render_css" do
    context "with valid path" do
      let(:path) { "pdf_generator/common_document.css" }
      let(:full_path) { "app/assets/stylesheets/#{path}" }
      let(:root) { n_double("root") }
      let(:assets_manifest) { n_double("assets_manifest") }
      let(:application) { n_double("application") }

      before do
        allow(Rails).to receive(:application).and_return(application)
        allow(application).to receive(:assets).and_return(assets)
      end

      context "when production" do
        let(:assets) { double(present?: false) }

        before do
          allow(application).to receive(:assets_manifest).and_return(assets_manifest)
          allow(assets_manifest).to receive(:assets).and_return(assets)
          allow(assets).to receive(:[]).with(path).and_return(path)
          allow(Rails).to receive(:root).and_return(root)
          allow(root).to receive(:join).with("public", "assets", path).and_return(full_path)
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with(full_path).at_least(:once)

          helper.render_css path
        end

        it { expect(assets).to have_received(:[]) }
        it { expect(File).to have_received(:read) }
      end

      context "when not production" do
        let(:assets) { double(present?: true) }

        before { allow(assets).to receive(:[]).with(path).and_return(full_path) }

        it { expect(helper.render_css(path)).to eq full_path }
      end
    end
  end

  describe ".extended_messenger_asset_map" do
    let(:map) do
      {
        "assets": {
          ".eslintrc-6528a78d75b7898dcca774b94f7218b7.js": ".eslintrc-6528a78d75b7898dcca774b94f7218b7-6528a78d75b7898dcca774b94f7218b7.js",
          ".eslintrc.js": ".eslintrc-6528a78d75b7898dcca774b94f7218b7.js",
          "assets/@clark/ops-messenger.css": "assets/@clark/ops-messenger-2b8291145f5fe8056ac36fd42e65b416.css",
          "assets/@clark/ops-messenger.js": "assets/@clark/ops-messenger-6e17db77421046a1042630cdf1007849.js",
          "assets/assetMap.json": "assets/assetMap.json",
          "assets/auto-import-fastboot.js": "assets/auto-import-fastboot-d41d8cd98f00b204e9800998ecf8427e.js",
          "assets/vendor.css": "assets/vendor-d41d8cd98f00b204e9800998ecf8427e.css",
          "assets/vendor.js": "assets/vendor-5571f33729360e34618ca0ade0cbcb83.js",
          "snippets.json": "snippets-ccc2d63596e175bbbb05b433e0299643.json"
        },
        "prepend": "https://s3.eu-central-1.amazonaws.com/test-test/"
      }.to_json
    end

    before do
      uri_double = double(read: map)
      allow(URI).to receive(:parse).and_return(uri_double)
    end

    it "fetches assets map" do
      expect(helper.extended_messenger_asset_map["assets/vendor.css"]).to eq(
        "https://s3.eu-central-1.amazonaws.com/test-test/assets/vendor-d41d8cd98f00b204e9800998ecf8427e.css"
      )

      expect(helper.extended_messenger_asset_map["assets/vendor.js"]).to eq(
        "https://s3.eu-central-1.amazonaws.com/test-test/assets/vendor-5571f33729360e34618ca0ade0cbcb83.js"
      )

      expect(helper.extended_messenger_asset_map["assets/@clark/ops-messenger.css"]).to eq(
        "https://s3.eu-central-1.amazonaws.com/test-test/assets/@clark/ops-messenger-2b8291145f5fe8056ac36fd42e65b416.css"
      )

      expect(helper.extended_messenger_asset_map["assets/@clark/ops-messenger.js"]).to eq(
        "https://s3.eu-central-1.amazonaws.com/test-test/assets/@clark/ops-messenger-6e17db77421046a1042630cdf1007849.js"
      )
    end
  end

  describe ".set_title" do
    context "when there's no meta.title fragment" do
      before do
        @cms_page = test_page
      end

      it "sets empty site_title" do
        expect(helper).to receive(:content_for).with(:site_title, "")
        helper.set_title
      end
    end
  end

  describe ".targeting_companies_list" do
    let(:dummy_class) { Class.new { include ApplicationHelper } }

    context "when active company exists" do
      let!(:company) { create(:company, name: "Basler") }

      it "returns company details" do
        expected_format = [
          {
            id: company.id,
            name: "Basler",
            name_without_hyphenation: "Basler",
            logo: ActionController::Base.helpers.asset_path(company.logo),
            ident: company.ident
          }
        ]
        results = dummy_class.new.targeting_companies_list

        expect(results.count).to eq(1)
        expect(results).to eq(expected_format)
      end
    end
  end
end

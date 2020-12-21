require 'rails_helper'

RSpec.describe Platform::UrlShortener do
  let(:subject) { described_class.new }
  let(:mandate) { create(:mandate) }
  let(:other_mandate) { create(:mandate) }

  before do
    site = double :site, hostname: "127.0.0.1:8200"
    allow(Comfy::Cms::Site).to receive(:find_by).with(identifier: "de").and_return site
  end

  it 'does not touch text without links' do
    text = "Cannot shorten me: and me as well"
    result = text
    expect(subject.replace_links(text, mandate)).to eq(result)
  end

  it 'does shorten text with links' do
    text = 'Will short http://google.com and '\
      'http://clark.de/my/giant/feed?query=12 :)'

    shortener_result = subject.replace_links(text, mandate)

    first_link = Shortener::ShortenedUrl.all[-2]
    second_link = Shortener::ShortenedUrl.last
    expected_result = 'Will short '\
      "https://127.0.0.1:8200/s/#{first_link&.unique_key} and "\
      "https://127.0.0.1:8200/s/#{second_link&.unique_key} :)"

    expect(shortener_result).to eq(expected_result)
  end

  it 'is different per mandate' do
    url = 'http://google.de'
    url_mandate = subject.replace_links(url, mandate)
    url_other_mandate = subject.replace_links(url, other_mandate)

    expect(url_mandate).not_to eq(url_other_mandate)
  end

  it 'does not short links without host' do
    text = 'Will NOT short /de/app/demandcheck'

    shortener_result = subject.replace_links(text, mandate)
    expect(shortener_result).to eq(text)
  end

  it 'shorten links with hosts' do
    url = subject.url_with_host('/de/app/demandcheck')
    text = 'Will short '+url
    shortener_result = subject.replace_links(text, mandate)

    short_url = Shortener::ShortenedUrl.last
    expected_result = 'Will short '\
      "https://127.0.0.1:8200/s/#{short_url&.unique_key}"

    expect(shortener_result).to eq(expected_result)
  end
end

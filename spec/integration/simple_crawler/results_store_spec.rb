require 'spec_helper'

describe SimpleCrawler::ResultsStore do

  let(:session) { SimpleCrawler::CrawlSession.new }
  subject { described_class.new crawl_session: session }

  let(:content_info1) do
    asset1 = create_asset "http://google.com/asset1.png"
    asset2 = create_asset "http://google.com/asset2.png"
    create_content "http://google.com/index.html", [asset1, asset2]
  end

  let(:content_info2) do
    asset1 = create_asset "http://google.com/asset1.png"
    asset2 = create_asset "http://google.com/asset3.png"
    create_content "http://google.com/about.html", [asset1, asset2]
  end

  let(:content_info3) do
    link1 = create_link "http://google.com/index.html"
    asset1 = create_asset "http://google.com/asset4.png"
    create_content "http://google.com/info.html", asset1, link1
  end

  let(:content_info4) do
    link1 = create_link "http://google.com/index.html"
    link2 = create_link "http://google.com/about.html"
    asset1 = create_asset "http://google.com/asset5.png"
    create_content "http://google.com/contact.html", asset1, [link1, link2]
  end

  before :each do
    [content_info1, content_info2, content_info3, content_info4].each do |content|
      subject.add_content content
    end
  end

  it "should be able to produce a dump to a directory" do
    Dir.mktmpdir do |tmp_dir|
      t = "#{tmp_dir}/"
      subject.dump t

      mapped_file = JSON.parse(open("#{t}map.json").read)
      assets_file = JSON.parse(open("#{t}assets.json").read)
      links_file = JSON.parse(open("#{t}incoming_links.json").read)

      expect(mapped_file).to match_array([
        {
          "uri" => "http://google.com/index.html",
          "assets" => [
            {"uri" => "http://google.com/asset1.png", "type" => "img"},
            {"uri" => "http://google.com/asset2.png", "type" => "img"}
          ],
          "links" => []
        },
        {
          "uri" => "http://google.com/about.html",
          "assets" => [
            {"uri" => "http://google.com/asset1.png", "type" => "img"},
            {"uri" => "http://google.com/asset3.png", "type" => "img"}
          ],
          "links" => []
        },
        {
          "uri" => "http://google.com/info.html",
          "assets" => [
            {"uri" => "http://google.com/asset4.png", "type" => "img"}
          ],
          "links" => [
            {"uri" => "http://google.com/index.html"}
          ]
        },
        {
          "uri" => "http://google.com/contact.html",
          "assets" => [
            {"uri" => "http://google.com/asset5.png", "type" => "img"}
          ],
          "links" => [
            {"uri" => "http://google.com/index.html"},
            {"uri" => "http://google.com/about.html"}
          ]
        }
      ])
    end
  end

end

require 'spec_helper'

describe SimpleCrawler::ContentFetcher do

  let(:session) { SimpleCrawler::CrawlSession.new }

  let(:url) { "http://callumj.com/a/b/index.html" }
  let(:dl) do
    double(:download_response).tap do |d|
      allow(d).to receive(:final_uri).and_return(URI.parse(url))
    end
  end
  subject { described_class.new url, session }

  before :each do
    dl_uri = double(:dl)
    allow(session).to receive(:absolute_uri_to).and_return(dl_uri)
    allow(SimpleCrawler::Downloader).to receive(:source_for).with(dl_uri).and_return(dl)
  end

  describe "#merge_uri_with_page" do

    it "should handle absolute links" do
      expect(subject.merge_uri_with_page("http://microsoft.com").to_s).to eq("http://microsoft.com/")
    end

    it "should handle scheme changes" do
      expect(subject.merge_uri_with_page("//microsoft.com").to_s).to eq("http://microsoft.com/")
    end

    it "should handle relative URLs" do
      expect(subject.merge_uri_with_page("/microsoft").to_s).to eq("http://callumj.com/microsoft")
      expect(subject.merge_uri_with_page("microsoft").to_s).to eq("http://callumj.com/a/b/microsoft")
    end

    it "should handle anchoring" do
      expect(subject.merge_uri_with_page("#microsoft").to_s).to eq("http://callumj.com/a/b/index.html#microsoft")
    end

    it "should handle query strings" do
      expect(subject.merge_uri_with_page("?microsoft=unsure").to_s).to eq("http://callumj.com/a/b/index.html?microsoft=unsure")
    end

    it "should handle invalid URI errors to return nil" do
      expect(Addressable::URI).to receive(:parse).with("/test") do
        raise Addressable::URI::InvalidURIError, "Some message"
      end

      expect(subject.merge_uri_with_page("/test")).to be_nil
    end

    it "should not mess with moving backwards" do
      expect(subject.merge_uri_with_page("../style/style.css").to_s).to eq("http://callumj.com/a/style/style.css")
    end

  end

  describe "can_be_downloaded?" do

    let(:url) { "http://callumj.com/a/b/index.html?some=junk" }

    it "should hand off to TypeHelper" do
      expect(SimpleCrawler::TypeHelper).to receive(:can_be_downloaded?).with("/a/b/index.html").and_return(false)
      expect(subject).to_not be_can_be_downloaded
    end

  end

  describe "#content_info" do

    context "unknown content" do

      before :each do
        expect(SimpleCrawler::Scrapers).to receive(:for).with(dl).and_return(nil)
      end

      it "should raise a error" do
        expect do
          subject.content_info
        end.to raise_error(SimpleCrawler::Errors::UnknownContent)
      end

    end

    context "known content" do

      let(:assets) { Array.new }
      let(:links) { Array.new }

      let(:scraped) do
        double(:scraped).tap do |s|
          expect(s).to receive(:assets).and_return(assets)
          expect(s).to receive(:links).and_return(links)
          expect(s).to receive(:title).and_return("TITLE")
        end
      end

      before :each do
        expect(SimpleCrawler::Scrapers).to receive(:for).with(dl).and_return(scraped)
      end

      it "should expose the asset objects" do
        assets << ["/image.png", "Some Image", "image"]
        assets << ["http://anz.com/thingo.css", "Some stylesheet", "stylesheet"]
        assets << ["c/d/magic.gif", "Some Gif", "giffy"]
        assets << ["DO NOT BREAK", "Some Gif", "giffy"]

        a1 = Addressable::URI.parse("a")
        a2 = Addressable::URI.parse("b")
        a3 = Addressable::URI.parse("c")

        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(assets[0][0])).and_return(a1)
        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(assets[1][0])).and_return(a2)
        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(assets[2][0])).and_return(a3)
        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(assets[3][0])).and_return(nil)

        expect(subject.content_info.assets.to_a).to match_array([
          SimpleCrawler::Models::Asset.new(a1, "image"),
          SimpleCrawler::Models::Asset.new(a2, "stylesheet"),
          SimpleCrawler::Models::Asset.new(a3, "giffy")
        ])
      end

      it "should expose the links objects" do
        links << ["/image.png", "Some Image"]
        links << ["http://anz.com/thingo.css", "Some stylesheet"]
        links << ["c/d/magic.gif", "Some Gif"]
        links << ["NOTEVENHERE", "Some Gif"]

        l1 = Addressable::URI.parse("a")
        l2 = Addressable::URI.parse("b")
        l3 = Addressable::URI.parse("c")

        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(links[0][0])).and_return(l1)
        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(links[1][0])).and_return(l2)
        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(links[2][0])).and_return(l3)
        expect(subject).to receive(:merge_uri_with_page).with(Addressable::URI.parse(links[3][0])).and_return(nil)

        expect(subject.content_info.links).to match_array([
          SimpleCrawler::Models::Link.new(l1),
          SimpleCrawler::Models::Link.new(l2),
          SimpleCrawler::Models::Link.new(l3)
        ])
      end

      it "should be resilient against broken assets or links" do
        links << ["http:", "Some Link"]
        assets << ["http:", "Some Image", "img"]

        expect(subject.content_info.links).to be_empty
        expect(subject.content_info.assets).to be_empty
      end

      it "should provide a relative URI in relation to the session" do
        uri = double(:uri).tap do |u|
          expect(u).to receive(:relative?).and_return(true)
          expect(u).to receive(:path).and_return("path")
        end
        expect(session).to receive(:relative_to).with(Addressable::URI.parse("http://callumj.com/a/b/index.html")).and_return(uri)

        inst = subject.content_info
        expect(inst.final_uri).to eq uri
      end

      it "should store a title" do
        expect(subject.content_info.title).to eq "TITLE"
      end
    end

  end

end

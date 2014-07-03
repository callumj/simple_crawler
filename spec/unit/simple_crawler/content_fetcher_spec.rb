require 'spec_helper'

describe SimpleCrawler::ContentFetcher do

  let(:url) { "http://callumj.com/a/b/index.html" }
  let(:dl) do
    double(:download_response).tap do |d|
      expect(d).to receive(:final_uri).and_return(URI.parse(url))
    end
  end
  subject { described_class.new url }

  before :each do
    expect(SimpleCrawler::Downloader).to receive(:source_for).with(url).and_return(dl)
  end

  describe "#merge_uri_with_page" do

    it "should handle absolute links" do
      expect(subject.merge_uri_with_page("http://microsoft.com").to_s).to eq("http://microsoft.com")
    end

    it "should handle scheme changes" do
      expect(subject.merge_uri_with_page("//microsoft.com").to_s).to eq("http://microsoft.com")
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

    it "should handle invalid URI errors and provide more context" do
      expect(Addressable::URI).to receive(:parse).with("http://callumj.com/a/b/index.html").and_call_original

      expect(Addressable::URI).to receive(:parse).with("/test") do
        raise Addressable::URI::InvalidURIError, "Some message"
      end

      expect do
        subject.merge_uri_with_page("/test")
      end.to raise_error(Addressable::URI::InvalidURIError, "Failed merging '/test' with 'http://callumj.com/a/b/index.html'")
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
        end
      end

      before :each do
        expect(SimpleCrawler::Scrapers).to receive(:for).with(dl).and_return(scraped)
      end

      it "should expose the asset objects" do
        assets << ["/image.png", "Some Image", "image"]
        assets << ["http://anz.com/thingo.css", "Some stylesheet", "stylesheet"]
        assets << ["c/d/magic.gif", "Some Gif", "giffy"]

        expect(subject.content_info.assets.to_a).to match_array([
          SimpleCrawler::Models::Asset.new(Addressable::URI.parse("http://callumj.com/image.png"), "image"),
          SimpleCrawler::Models::Asset.new(Addressable::URI.parse("http://anz.com/thingo.css"), "stylesheet"),
          SimpleCrawler::Models::Asset.new(Addressable::URI.parse("http://callumj.com/a/b/c/d/magic.gif"), "giffy")
        ])
      end

      it "should expose the links objects" do
        links << ["/image.png", "Some Image"]
        links << ["http://anz.com/thingo.css", "Some stylesheet"]
        links << ["c/d/magic.gif", "Some Gif"]

        expect(subject.content_info.links).to match_array([
          SimpleCrawler::Models::Link.new(Addressable::URI.parse("http://callumj.com/image.png")),
          SimpleCrawler::Models::Link.new(Addressable::URI.parse("http://anz.com/thingo.css")),
          SimpleCrawler::Models::Link.new(Addressable::URI.parse("http://callumj.com/a/b/c/d/magic.gif"))
        ])
      end
    end

  end

end

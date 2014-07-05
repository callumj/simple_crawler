  require 'spec_helper'

describe SimpleCrawler::ResultsStore do

  let(:session) { SimpleCrawler::CrawlSession.new }
  subject { described_class.new crawl_session: session }

  describe "initializing" do

    it "should require a crawl_session" do
      expect do
        described_class.new thing: true
      end.to raise_error(ArgumentError, "A CrawlSession is required!")
    end


    it "should accept a crawl_session" do
      expect(subject.crawl_session).to eq(session)
      expect(subject.contents).to be_a(Set)
    end

  end

  describe "#add_content" do

    let(:uri) { Addressable::URI.parse "http://enron.com/ethics" }
    let(:content_info) { SimpleCrawler::Models::ContentInfo.new uri }

    it "should append the content info to the set" do
      expect do
        subject.add_content content_info
      end.to change { subject.contents.include?(content_info) }.from(false).to(true)
    end

    it "should enumerate the assets" do
      expect(content_info).to receive(:assets).and_return([])
      subject.add_content content_info
    end

    it "should enumerate the links" do
      expect(content_info).to receive(:links).and_return([])
      subject.add_content content_info
    end

    it "should add it to local_stylesheets if it is a stylesheet" do
      expect(content_info).to receive(:assets).and_return([])
      expect(content_info).to_not receive(:links)

      expect(content_info).to receive(:stylesheet?).and_return(true)
      expect do
        subject.add_content content_info
      end.to change { subject.local_stylesheets.include?(content_info) }.from(false).to(true)
    end
  end

end

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
      expect(subject).to receive(:record_title).with(content_info)
      expect(subject).to receive(:attach_callback).with(content_info)

      expect do
        subject.add_content content_info
      end.to change { subject.contents.include?(content_info) }.from(false).to(true)
    end

    it "should enumerate the assets" do
      expect(subject).to receive(:record_title).with(content_info)
      expect(subject).to receive(:attach_callback).with(content_info)

      expect(content_info).to receive(:assets).and_return([])
      subject.add_content content_info
    end

    it "should enumerate the links" do
      expect(subject).to receive(:record_title).with(content_info)
      expect(subject).to receive(:attach_callback).with(content_info)

      expect(content_info).to receive(:links).and_return([])
      subject.add_content content_info
    end

    it "should attach callbacks to the links" do
      l = double(:link).tap do |l|
        expect(l).to receive(:uri)
      end
      expect(subject).to receive(:record_title).with(content_info)
      expect(subject).to receive(:attach_callback).with(content_info)
      expect(subject).to receive(:attach_callback).with(l)

      expect(content_info).to receive(:links).and_return([l])
      subject.add_content content_info
    end

    it "should add it to local_stylesheets if it is a stylesheet" do
      expect(content_info).to receive(:assets).and_return([])
      expect(content_info).to_not receive(:links)

      expect(subject).to_not receive(:record_title).with(content_info)
      expect(subject).to_not receive(:attach_callback).with(content_info)

      expect(content_info).to receive(:stylesheet?).and_return(true)
      expect do
        subject.add_content content_info
      end.to change { subject.local_stylesheets.include?(content_info) }.from(false).to(true)
    end
  end

  describe "#record_title" do

    let(:content_info) { double(:content_info) }

    it "should bail out if the content_info has no incoming_title" do
      expect(content_info).to receive(:incoming_title).and_return(nil)
      subject.record_title content_info
    end

    it "should record the details in a map" do
      addr = Addressable::URI.parse("http://google.com/a/b/page.html?stuff=true#about")
      expect(content_info).to receive(:incoming_title).and_return("Title").twice
      expect(content_info).to receive(:uri).and_return(addr).exactly(4).times

      subject.record_title content_info
      expect(subject.title_map["http://google.com/a/b/page.html"]["stuff=true"]).to eq "Title"
    end

    it "should use queryless as default" do
      addr = Addressable::URI.parse("http://google.com/a/b/page.html")
      expect(content_info).to receive(:incoming_title).and_return("Title").twice
      expect(content_info).to receive(:uri).and_return(addr).exactly(4).times

      subject.record_title content_info
      expect(subject.title_map["http://google.com/a/b/page.html"][:default]).to eq "Title"
    end

  end

  describe "#fetch_title" do

    set = {
      a: ["http://google.com/a/b/page.html", "Title"],
      b: ["http://google.com/a/b/about.html", "About"],
      c: ["http://google.com/a/b/about.html?info=true#details", "About Me"],
    }

    set.each do |name, (url, title)|
      sym = :"content_info#{name}"
      let(sym) do
        double(sym).tap do |c|
          addr = Addressable::URI.parse(url)
          allow(c).to receive(:incoming_title).and_return(title)
          allow(c).to receive(:uri).and_return(addr)
        end
      end
    end

    before :each do
      subject.record_title content_infoa
      subject.record_title content_infob
      subject.record_title content_infoc
    end

    it "should be able to find the records" do
      expect(subject.fetch_title(content_infoa)).to eq set[:a][1]
      expect(subject.fetch_title(content_infob)).to eq set[:b][1]
      expect(subject.fetch_title(content_infoc)).to eq set[:c][1]
    end

    it "should be able to fallback to default" do
      con = double(:content_info).tap do |c|
        addr = Addressable::URI.parse("http://google.com/a/b/about.html?info=false#details")
        allow(c).to receive(:uri).and_return(addr)
      end

      expect(subject.fetch_title(con)).to eq "About"
    end

  end

  describe "#attach_callback" do

    it "should add a Proc pointing to #fetch_title" do
      @missing_title_callback = nil
      target = double(:target).tap do |t|
        expect(t).to receive(:missing_title_callback=).with(kind_of(Proc)) do |arg|
          @missing_title_callback = arg
        end
      end

      subject.attach_callback(target)
      expect(subject).to receive(:fetch_title).with(target)

      @missing_title_callback.call
    end

  end

end

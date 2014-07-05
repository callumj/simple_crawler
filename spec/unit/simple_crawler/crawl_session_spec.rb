require 'spec_helper'

describe SimpleCrawler::CrawlSession do

  subject { described_class.new initial_url: "http://digitalocean.com", output: "/some/output" }

  describe "initializing" do

    it "should accept a initial_url" do
      expect(subject.initial_uri).to eq(Addressable::URI.parse("http://digitalocean.com/"))
      expect(subject.initial_url).to eq("http://digitalocean.com/")
      expect(subject.host_restriction).to eq("digitalocean.com")
    end

    it "should accept an output" do
      expect(subject.output).to eq("/some/output")
    end

  end

  describe "#absolute_uri_to" do
    
    it "should join a relative with the initial" do
      expect(subject.absolute_uri_to("/info.html")).to eq Addressable::URI.parse("http://digitalocean.com/info.html")
    end

    it "should return the provided if no initial_uri is known" do
      expect(subject).to receive(:initial_uri).and_return(nil)
      expect(subject.absolute_uri_to("/info.html")).to eq Addressable::URI.parse("/info.html")
    end

  end

  describe "#relative_to" do
    
    it "should be able to produce a relative URI to the known" do
      expect(subject.relative_to("http://digitalocean.com/pages/info.html")).to eq Addressable::URI.parse("/pages/info.html")
    end

    it "should return the provided if no initial_uri is known" do
      expect(subject).to receive(:initial_uri).and_return(nil)
      expect(subject.relative_to("http://digitalocean.com/pages/info.html")).to eq Addressable::URI.parse("http://digitalocean.com/pages/info.html")
    end

  end

  describe "#valid_host?" do

    subject { described_class.new }

    it "should be true with no restriction" do
      expect(subject).to be_valid_host(URI.parse("http://domain.com"))
      expect(subject).to be_valid_host(URI.parse("http://enron.com"))
    end

    it "should be matching on string level when a string" do
      inst = described_class.new host_restriction: "domain.com"
      expect(inst).to be_valid_host(URI.parse("http://domain.com"))
      expect(inst).to be_valid_host(URI.parse("http://DOMAIN.com"))

      expect(inst).to_not be_valid_host(URI.parse("http://sub.domain.com"))
      expect(inst).to_not be_valid_host(URI.parse("http://subdomain.com"))
    end

    it "should be matching on a regex level when a regexp" do
      inst = described_class.new host_restriction: /(^|\.)domain.com/i
      expect(inst).to be_valid_host(URI.parse("http://domain.com"))
      expect(inst).to be_valid_host(URI.parse("http://DOMAIN.com"))
      expect(inst).to be_valid_host(URI.parse("http://sub.domain.com"))

      expect(inst).to_not be_valid_host(URI.parse("http://subdomain.com"))
    end

    it "should be true if the URI is relative" do
      inst = described_class.new host_restriction: "domain.com"
      expect(subject).to be_valid_host(URI.parse("/thing.gif"))
    end

  end

  describe "#add_content" do

    let(:content_info) { double :content_info }

    before :each do
      expect(subject.results_store).to receive(:add_content).with(content_info)
    end

    it "should add the content" do
      expect(content_info).to receive(:links).and_return([])
      expect(content_info).to receive(:assets).and_return([])

      subject.add_content content_info
    end

    it "should queue the links" do
      expect(content_info).to receive(:assets).and_return([])

      l1 = double(:l1).tap { |d| expect(d).to receive(:uri).and_return("lu1") }
      l2 = double(:l2).tap { |d| expect(d).to receive(:uri).and_return("lu2") }
      expect(content_info).to receive(:links).and_return([l1, l2])
      expect(subject.queue).to receive(:enqueue).with("lu1")
      expect(subject.queue).to receive(:enqueue).with("lu2")

      subject.add_content content_info
    end

    it "should queue only the stylesheet assets" do
      expect(content_info).to receive(:links).and_return([])

      l1 = double(:l1).tap do |d|
        expect(d).to receive(:stylesheet?).and_return(false)
      end
      l2 = double(:l2).tap do |d|
        expect(d).to receive(:stylesheet?).and_return(true)
        expect(d).to receive(:uri).and_return("lu2")
      end
      expect(content_info).to receive(:assets).and_return([l1, l2])
      expect(subject.queue).to receive(:enqueue).with("lu2")

      subject.add_content content_info
    end

  end

  describe "#queue" do

    subject { described_class.new }

    it "should return a GlobalQueue" do
      expect(subject.queue).to be_a(SimpleCrawler::GlobalQueue)

      inst = subject.queue
      expect(subject.queue).to eq inst
      expect(inst.crawl_session).to eq subject
    end

    it "should return an appended initial_uri where available" do
      uri = Addressable::URI.parse("http://intel.com")
      expect(subject).to receive(:initial_uri).and_return(uri).twice

      q = subject.queue
      expect(q.peek).to eq uri
    end

  end

  describe "#storage" do

    it "should return an initialized StorageAdapters::File" do
      s_f = double(:s_f)
      expect(SimpleCrawler::StorageAdapters::File).to receive(:new).with(crawl_session: subject, output: "/some/output").and_return(s_f)

      expect(subject.storage).to eq s_f
    end

  end

  describe "#dump_results" do

    it "should send a sync to the storage" do
      storage = double(:storage).tap do |s|
        expect(s).to receive(:sync)
      end
      expect(subject).to receive(:storage).and_return(storage)

      subject.dump_results
    end

  end

end

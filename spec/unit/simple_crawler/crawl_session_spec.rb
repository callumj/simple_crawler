require 'spec_helper'

describe SimpleCrawler::CrawlSession do

  subject { described_class.new initial_url: "http://digitalocean.com" }

  describe "initializing" do

    it "should accept a initial_url" do
      expect(subject.initial_uri).to eq(Addressable::URI.parse("http://digitalocean.com/"))
      expect(subject.initial_url).to eq("http://digitalocean.com/")
      expect(subject.host_restriction).to eq("digitalocean.com")
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

end

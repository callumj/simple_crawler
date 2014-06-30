require 'spec_helper'

describe SimpleCrawler::GlobalQueue do

  before :each do
    described_class.flush_instance!
  end

  describe ".setup_instance!" do

    it "should setup a global instance" do
      expect(described_class.instance).to be_nil

      described_class.setup_instance! host_restriction: "SOME_THING"
      expect(described_class.instance.host_restriction).to eq "SOME_THING"
    end

  end

  describe "#new" do

    it "should not permit another instance if a global instance is running" do
      described_class.setup_instance! host_restriction: "SOME_THING"

      expect do
        described_class.new
      end.to raise_error(SimpleCrawler::Errors::InstanceAlreadyRunning)
    end

    it "should pass in the host_restriction" do
      inst = described_class.new some: :thing, host_restriction: "domain.com"
      expect(inst.host_restriction).to eq "domain.com"
    end

    it "should initialise the basics" do
      expect(subject.known_uris).to be_a(Array)
      expect(subject.known_uris).to be_empty
    end

  end

  describe "#valid_host?" do

    it "should be true with no restriction" do
      expect(subject).to be_valid_host("domain.com")
      expect(subject).to be_valid_host("enron.com")
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

  end

  describe "#visited_before?" do

    it "should remove fragments" do
      uri_a = Addressable::URI.parse "http://google.com/index.html"
      uri_b = Addressable::URI.parse "http://google.com/index.html#sss"
      uri_c = Addressable::URI.parse "http://google.com/index.html?q=s#sss"

      subject.enqueue uri_a
      expect(subject).to be_visited_before(uri_b)
      expect(subject).to_not be_visited_before(uri_c)
    end

  end

  describe "#can_enqueue?" do

    it "should check it is a valid_host and has not been visited before" do
      uri_a = Addressable::URI.parse "http://google.com/index.html"
      expect(subject).to receive(:valid_host?).with(uri_a).and_return(true)
      expect(subject).to receive(:visited_before?).with(uri_a).and_return(false)

      expect(subject).to be_can_enqueue(uri_a)
    end

    it "should be false if not a valid host" do
      uri_a = Addressable::URI.parse "http://google.com/index.html"
      expect(subject).to receive(:valid_host?).with(uri_a).and_return(false)
      expect(subject).to_not receive(:visited_before?).with(uri_a)

      expect(subject).to_not be_can_enqueue(uri_a)
    end

    it "should be false if visited before" do
      uri_a = Addressable::URI.parse "http://google.com/index.html"
      expect(subject).to receive(:valid_host?).with(uri_a).and_return(true)
      expect(subject).to receive(:visited_before?).with(uri_a).and_return(true)

      expect(subject).to_not be_can_enqueue(uri_a)
    end

  end

end
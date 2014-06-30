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
      expect(subject.known_uris).to be_a(Set)
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

  describe "queue manipulation" do

    it "should silently fail when the URI cannot be enqueued" do
      uri = Addressable::URI.parse "http://google.com"
      expect(subject).to receive(:can_enqueue?).with(uri).and_return(false)

      expect(subject.enqueue(uri)).to eq false
    end

    it "should add when the URI can be enqueued" do
      uri = Addressable::URI.parse "http://google.com"
      expect(subject).to receive(:can_enqueue?).with(uri).and_return(true)

      expect(subject.enqueue(uri)).to eq true
      expect(subject.peek).to eq uri
    end

    context "multiple enqueuing" do

      let(:uri1) { Addressable::URI.parse "http://google.com" }
      let(:uri2) { Addressable::URI.parse "http://google.com" }
      let(:uri3) { Addressable::URI.parse "http://google.com/index.html" }
      let(:uri4) { Addressable::URI.parse "http://google.com/rails.html" }

      before :each do
        [uri1, uri2, uri3, uri4].each do |o|
          subject.enqueue o
        end
      end

      it "should be dequeuing in order" do
        expect(subject.dequeue).to eq uri1
        expect(subject.dequeue).to eq uri3
        expect(subject.dequeue).to eq uri4
        expect(subject.dequeue).to be_nil
      end

      it "should be able to restore after a queue depletition" do
        3.times { subject.dequeue }

        uri6 = Addressable::URI.parse "http://googly.com"
        uri7 = Addressable::URI.parse "http://googlo.com"

        subject.enqueue(uri6)
        subject.enqueue(uri4)
        subject.enqueue(uri7)

        expect(subject.dequeue).to eq uri6
        expect(subject.dequeue).to eq uri7
      end

      it "should safely handle competing threads" do
        3.times { subject.dequeue }

        uri6 = Addressable::URI.parse "http://googly.com"
        uri7 = Addressable::URI.parse "http://googlo.com"
        uri8 = Addressable::URI.parse "http://googl0.com"
        uri9 = Addressable::URI.parse "http://googly.com"

        Thread.new { subject.enqueue(uri6) }
        Thread.new { subject.enqueue(uri4) }
        Thread.new { subject.enqueue(uri7) }
        Thread.new { subject.enqueue(uri8) }
        Thread.new { subject.enqueue(uri9) }

        res = 3.times.map { subject.dequeue }
        expect(subject.dequeue).to be_nil

        expect(res).to match_array [uri6, uri7, uri8]
      end

    end

  end

end
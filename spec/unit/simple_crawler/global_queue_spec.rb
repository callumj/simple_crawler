require 'spec_helper'

describe SimpleCrawler::GlobalQueue do

  let(:crawl_session) { SimpleCrawler::CrawlSession.new }
  let(:default_init) { {crawl_session: crawl_session} }

  let(:subject) { described_class.new default_init }

  describe "#new" do

    it "should require a crawl_session" do
      expect do
        described_class.new some: :thing
      end.to raise_error(ArgumentError, "A CrawlSession is required!")
    end

    it "should pass in the crawl_session" do
      inst = described_class.new default_init.merge(some: :thing, host_restriction: "domain.com")
      expect(inst.crawl_session).to eq crawl_session
    end

    it "should initialise the basics" do
      expect(subject.known_uris).to be_a(Set)
      expect(subject.known_uris).to be_empty
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
      expect(crawl_session).to receive(:valid_host?).with(uri_a).and_return(true)
      expect(subject).to receive(:visited_before?).with(uri_a).and_return(false)

      expect(subject).to be_can_enqueue(uri_a)
    end

    it "should be false if not a valid host" do
      uri_a = Addressable::URI.parse "http://google.com/index.html"
      expect(crawl_session).to receive(:valid_host?).with(uri_a).and_return(false)
      expect(subject).to_not receive(:visited_before?).with(uri_a)

      expect(subject).to_not be_can_enqueue(uri_a)
    end

    it "should be false if visited before" do
      uri_a = Addressable::URI.parse "http://google.com/index.html"
      expect(crawl_session).to receive(:valid_host?).with(uri_a).and_return(true)
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

        t1 = Thread.new { subject.enqueue(uri6) }
        t2 = Thread.new { subject.enqueue(uri4) }
        t3 = Thread.new { subject.enqueue(uri7) }
        t4 = Thread.new { subject.enqueue(uri8) }
        t5 = Thread.new { subject.enqueue(uri9) }

        while [t1, t2, t3, t4, t5].any? { |t| t.alive? }
        end

        res = 3.times.map { subject.dequeue }
        expect(subject.dequeue).to be_nil

        expect(res).to match_array [uri6, uri7, uri8]
      end

    end

  end

end
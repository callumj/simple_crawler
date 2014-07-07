require 'spec_helper'

describe SimpleCrawler::Client::CrawlSession do

  let(:info) do
    {
      initial_uri: Addressable::URI.parse("http://bling.com/index.html")
    }
  end

  let(:message) do
    double(:message).tap do |m|
      allow(m).to receive(:object).and_return(info)
    end
  end

  let(:connection) do
    double(:connection).tap do |c|
      allow(c).to receive(:send_message).with("info", nil).and_return(message)
    end
  end
  subject { described_class.new connection }

  describe "initializing" do

    it "should set the initial URI and host restriction" do
      expect(subject.initial_uri).to eq info[:initial_uri]
      expect(subject.host_restriction).to eq "bling.com"
    end

  end

  describe "#add_content" do

    it "should send to the connection" do
      con = double :content_info
      expect(connection).to receive(:send_message).with("add_content", con)

      subject.add_content con
    end

  end

  describe "#queue" do

    it "should be a remote queue proxy" do
      q = subject.queue
      expect(q).to be_a(described_class::RemoteQueue)
      expect(q.connection).to eq connection
    end

  end

  describe "#results_store" do

    it "should not allow to be called" do
      expect do
        subject.results_store
      end.to raise_error(NotImplementedError)
    end

  end

  describe "#storage" do

    it "should not allow to be called" do
      expect do
        subject.storage
      end.to raise_error(NotImplementedError)
    end

  end

  describe "#notify_of_failure" do

    it "should send to the connection" do
      deq = double :deq
      expect(connection).to receive(:send_message).with("ignore", deq)

      subject.notify_of_failure deq
    end

  end

  describe SimpleCrawler::Client::CrawlSession::RemoteQueue do

    subject { described_class.new connection }

    it "should forward peek to the connection" do
      obj = double :object
      peeked = double(:peek).tap do |p|
        expect(p).to receive(:object).and_return(obj)
      end
      expect(connection).to receive(:send_message).with("peek", nil).and_return(peeked)

      expect(subject.peek).to eq obj
    end

    it "should forward dequeue to the connection" do
      obj = double :object
      peeked = double(:dequeue).tap do |p|
        expect(p).to receive(:object).and_return(obj)
      end
      expect(connection).to receive(:send_message).with("dequeue", nil).and_return(peeked)

      expect(subject.dequeue).to eq obj
    end

  end

end

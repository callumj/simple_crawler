require 'spec_helper'

describe SimpleCrawler::Server do

  let(:session) { SimpleCrawler::CrawlSession.new initial_url: "http://google.com" }
  let(:args) { {crawl_session: session} }
  subject { described_class.new args }

  describe "initializing" do

    it "should require a crawl session" do
      expect do
        described_class.new some_args: true
      end.to raise_error(ArgumentError, "A CrawlSession is required!")
    end

    it "should create a default TCPServer" do
      tcp = double :server
      expect(TCPServer).to receive(:new).with("0.0.0.0", described_class::DEFAULT_PORT).and_return(tcp)

      expect(subject.server).to eq tcp
    end

    it "should allow for specifying a port" do
      tcp = double :server
      expect(TCPServer).to receive(:new).with("0.0.0.0", 8090).and_return(tcp)

      args[:listen] = ":8090"
      expect(subject.server).to eq tcp
    end

    it "should allow for specifying host and port" do
      tcp = double :server
      expect(TCPServer).to receive(:new).with("127.0.1.2", 8090).and_return(tcp)

      args[:listen] = "127.0.1.2:8090"
      expect(subject.server).to eq tcp
    end

  end

  context "running" do

    let(:tcp) { double :server }

    before :each do
      expect(TCPServer).to receive(:new).with("0.0.0.0", described_class::DEFAULT_PORT).and_return(tcp)
    end

    describe "#serve" do

      it "should loop until no longer active, awaiting connection and starting a process" do
        state = true
        expect(subject).to receive(:active?).twice do
          res = state
          state = false
          res
        end

        sock = double :sock
        expect(tcp).to receive(:accept).and_return(sock)
        expect(subject).to receive(:process).with(sock)

        sleep 0.05

        subject.serve
      end

    end

    describe "#monitor_for_shutdown" do

      let(:queue) { double :queue }

      before :each do
        allow(session).to receive(:queue).and_return(queue)
      end

      it "should wait until there are nothing running/awaiting response" do
        expect(queue).to receive(:peek).and_return(nil).exactly(described_class::SHUTDOWN_AFTER_EMPTY_FOR + 1).times

        expect(subject).to receive(:shutdown!)
        expect(subject).to receive(:sleep).with(described_class::SLEEP_FOR).exactly(described_class::SHUTDOWN_AFTER_EMPTY_FOR).times

        subject.monitor_for_shutdown
      end

    end

    describe "#process" do

      it "should gets from socket until it sees the finish marker" do
        str = [
          "1",
          "2",
          "3",
          described_class::FINISH_STR,
          nil
        ]

        socket = double(:socket).tap do |s|
          expect(s).to receive(:gets).exactly(5).times do 
            str.shift
          end
        end

        marsh = double :marsh
        expect(Marshal).to receive(:load).with("123").and_return(marsh)
        expect(subject).to receive(:handle_message).with(marsh).and_return(nil)

        subject.process socket
      end

      it "should close the socket if the close is handle_message" do
        str = [
          "1",
          "2",
          "3",
          described_class::FINISH_STR
        ]

        socket = double(:socket).tap do |s|
          expect(s).to receive(:gets).exactly(4).times do 
            str.shift
          end
          expect(s).to receive(:close)
        end

        marsh = double :marsh
        expect(Marshal).to receive(:load).with("123").and_return(marsh)
        expect(subject).to receive(:handle_message).with(marsh).and_return(:close)

        subject.process socket
      end

      it "should send back the message" do
        str = [
          "1",
          "2",
          "3",
          described_class::FINISH_STR,
          nil
        ]

        socket = double(:socket).tap do |s|
          expect(s).to receive(:gets).exactly(5).times do 
            str.shift
          end
          expect(s).to receive(:puts).with("PACKED!")
          expect(s).to receive(:puts).with(described_class::FINISH_STR)
        end

        marsh = double :marsh
        dumpable = double :dumpable

        expect(Marshal).to receive(:load).with("123").and_return(marsh)
        expect(Marshal).to receive(:dump).with(dumpable).and_return("PACKED!")
        expect(subject).to receive(:handle_message).with(marsh).and_return(dumpable)

        subject.process socket
      end

    end

    describe "#handle_message" do

      def msg(op, object = nil)
        SimpleCrawler::Client::Message.new op, object
      end

      it "should return info" do
        inf = double :info
        expect(session).to receive(:info).and_return(inf)
        expect(subject.handle_message(msg("info")).object).to eq inf
      end

      describe "add_content" do

        let(:uri) { double :uri }
        let(:content) do
          double(:content_info).tap do |c|
            expect(c).to receive(:original_uri).and_return(uri)
          end
        end

        before :each do
          expect(session).to receive(:add_content).with(content)
        end

        it "should be able to add content" do
          expect(subject.handle_message(msg("add_content", content))).to eq true
        end

        it "should remove it from an awaiting" do
          expect(uri).to receive(:to_s).and_return("SW4")
          set = Set.new ["SW4"]
          subject.instance_variable_set :@awaiting_uris, set

          expect do
            expect(subject.handle_message(msg("add_content", content))).to eq true
          end.to change { set.empty? }.from(false).to(true)
        end

      end

      it "should support peek" do
        peeked = double :peeked
        queue = double(:queue).tap do |q|
          expect(q).to receive(:peek).and_return(peeked)
        end

        expect(session).to receive(:queue).and_return(queue)

        expect(subject.handle_message(msg("peek")).object).to eq peeked
      end

      it "should allow removing items from awaiting" do
        set = Set.new ["SW4"]
        subject.instance_variable_set :@awaiting_uris, set

        expect do
          expect(subject.handle_message(msg("ignore", "SW4"))).to eq true
        end.to change { set.empty? }.from(false).to(true)
      end

      it "should allow for dequeing" do
        dequeued = double(:dequeued).tap do |p|
          expect(p).to receive(:to_s).and_return("N102DL")
        end
        queue = double(:queue).tap do |q|
          expect(q).to receive(:dequeue).and_return(dequeued)
        end

        set = Set.new
        subject.instance_variable_set :@awaiting_uris, set

        expect(session).to receive(:queue).and_return(queue)

        expect do
          expect(subject.handle_message(msg("dequeue")).object).to eq dequeued
        end.to change { set.include?("N102DL") }.from(false).to(true)
      end

      it "should allow for closing" do
        expect(subject.handle_message(msg("close"))).to eq :close
      end

    end

  end

end

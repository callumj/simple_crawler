require 'spec_helper'

describe SimpleCrawler::Client::Connection do

  describe "initializing" do

    it "should initialize with defaults on a TCPSocket" do
      socket = double :socket
      expect(TCPSocket).to receive(:new).with("127.0.0.1", SimpleCrawler::Server::DEFAULT_PORT).and_return(socket)

      expect(described_class.new.socket).to eq socket
    end

    it "should pass down the port and host" do
      socket = double :socket
      expect(TCPSocket).to receive(:new).with("127.1.1.2", 9172).and_return(socket)

      expect(described_class.new(9172, "127.1.1.2").socket).to eq socket
    end

  end

  describe "#send_message" do

    let(:socket) { double :socket }

    before :each do
      expect(TCPSocket).to receive(:new).with("127.0.0.1", SimpleCrawler::Server::DEFAULT_PORT).and_return(socket)
    end

    it "should send down a marshalled message, reading back from server" do
      mes = double :mes
      expect(SimpleCrawler::Client::Message).to receive(:new).with("some_op", "data").and_return(mes)
      expect(Marshal).to receive(:dump).with(mes).and_return("marshal-mathers")

      expect(socket).to receive(:puts).with("marshal-mathers")
      expect(socket).to receive(:puts).with(SimpleCrawler::Server::FINISH_STR)

      set = [
        "1",
        "2",
        "3",
        SimpleCrawler::Server::FINISH_STR
      ]
      expect(socket).to receive(:gets).exactly(4).times do
        set.shift
      end

      marsh = double :marshal
      expect(Marshal).to receive(:load).with("123").and_return(marsh)

      expect(subject.send_message("some_op", "data")).to eq marsh
    end

  end

end

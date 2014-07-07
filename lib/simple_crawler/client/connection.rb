require 'socket'
require 'thread'

module SimpleCrawler
  module Client
    class Connection

      attr_reader :socket

      def initialize(port = nil, host = nil)
        port = Server::DEFAULT_PORT if port.nil?
        host = "127.0.0.1" if host.nil?
        @socket = TCPSocket.new host, port
        @lock = Mutex.new
      end

      def send_message(op, object)
        res = nil
        @lock.synchronize do
          m = Message.new op, object
          @socket.puts Marshal.dump(m)
          @socket.puts Server::FINISH_STR
          data = ""
          until (resp = @socket.gets).strip == Server::FINISH_STR
            data << resp
          end

          res = Marshal.load data
        end
        res
      end

    end
  end
end

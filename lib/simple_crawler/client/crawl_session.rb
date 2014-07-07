module SimpleCrawler
  module Client
    class CrawlSession < SimpleCrawler::CrawlSession

      class RemoteQueue

        attr_reader :connection

        def initialize(connection)
          @connection = connection
        end

        def peek
          resp = connection.send_message "peek", nil
          resp.object
        end

        def dequeue
          resp = connection.send_message "dequeue", nil
          resp.object
        end

      end

      attr_reader :initial_url, :connection, :host_restriction

      def initialize(connection)
        @connection = connection
        info = connection.send_message "info", nil

        @initial_uri = info.object[:initial_uri]
        @host_restriction = @initial_uri.host
      end

      def add_content(content_info)
        # send a message
        connection.send_message "add_content", content_info
      end

      def queue
        @queue ||= RemoteQueue.new connection
      end

      def results_store
        raise NotImplementedError, "Please use add_content"
      end

      def storage
        raise NotImplementedError, "Please use add_content"
      end

      def dump_results
      end

      def notify_of_failure(dequeued_uri)
        connection.send_message "ignore", dequeued_uri
      end
    end
  end
end

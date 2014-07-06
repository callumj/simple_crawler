module SimpleCrawler
  module StorageAdapters
    class Base

      attr_accessor :crawl_session

      def initialize(opts = {})
        @crawl_session = opts[:crawl_session]
        raise ArgumentError, "CrawlSession must be provided" unless @crawl_session.is_a?(CrawlSession)
      end

      def queue
        crawl_session.queue
      end

      def results_store
        crawl_session.results_store
      end

      def sync
      end

      def finish_up
      end

      def records_changed(num)
        false
      end

    end
  end
end

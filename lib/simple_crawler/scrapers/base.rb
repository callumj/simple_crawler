module SimpleCrawler
  module Scrapers
    class Base

      def title
        nil
      end

      def links
        raise NotImplementedError
      end

      def assets
        raise NotImplementedError
      end

    end
  end
end

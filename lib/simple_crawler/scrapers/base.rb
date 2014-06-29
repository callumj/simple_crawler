module SimpleCrawler
  module Scrapers
    class Base

      def links
        raise NotImplementedError
      end

      def assets
        raise NotImplementedError
      end

    end
  end
end

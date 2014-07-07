module SimpleCrawler
  module Extensions
    module MissingTitle

      def self.included(base)
        attr_accessor :missing_title_callback
      end

      def fallback_to_missing_title
        !@missing_title_callback.nil? && missing_title_callback.call
      end

    end
  end
end
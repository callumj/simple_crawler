module SimpleCrawler
  module Models
    class ContentInfo

      attr_accessor :final_uri

      def initialize(final_uri, assets = nil, links = nil)
        self.final_uri = final_uri
        @assets = Utils.set_from_possible_array assets, Asset
        @links = Utils.set_from_possible_array links, Link
      end

      def assets
        @assets.freeze
      end

      def links
        @links.freeze
      end

      def add_links(link_or_ary)
        @links
      end

    end
  end
end

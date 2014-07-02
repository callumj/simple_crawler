module SimpleCrawler
  module Models
    class Asset

      attr_reader :uri, :type

      def initialize(uri, type)
        @uri = uri
        @type = type
      end

      def hash
        @uri.hash
      end

      def eql?(other_asset)
        other_asset.uri == @uri
      end

      def ==(other_asset)
        eql? other_asset
      end

    end
  end
end

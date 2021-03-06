module SimpleCrawler
  module Models
    class Asset

      attr_reader :uri

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

      def type
        @type ||= TypeHelper.type_from_name uri.path
      end

      def as_json
        {
          uri: uri.to_s,
          type: type
        }
      end

      def stylesheet?
        type == "stylesheet"
      end

    end
  end
end

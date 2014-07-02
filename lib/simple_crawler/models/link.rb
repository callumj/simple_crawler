module SimpleCrawler
  module Models
    class Link

      attr_reader :uri

      def initialize(uri)
        @uri = uri
      end

      def hash
        @uri.hash
      end

      def eql?(other_link)
        other_link.uri == @uri
      end

      def ==(other_link)
        eql? other_link
      end

      def as_json
        {
          uri: uri.to_s
        }
      end

    end
  end
end

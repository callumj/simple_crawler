module SimpleCrawler
  module Models
    class Link

      include Extensions::MissingTitle

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
          uri: uri.to_s,
          title: title
        }
      end

      def title
        @title ||= fallback_to_missing_title
      end

    end
  end
end

require 'addressable/uri'

module SimpleCrawler
  class ContentFetcher

    attr_accessor :url

    def initialize(url)
      @url = url
    end

    def content_info
      @content_info ||= Models::ContentInfo.new(final_uri, assets, links)
    end

    def merge_uri_with_page(uri)
      uri = Addressable::URI.parse(uri) unless uri.is_a?(Addressable::URI)
      return final_uri.join uri
    end

    private

      def final_uri
        @final_uri ||= Addressable::URI.parse(response.final_uri.to_s)
      end

      def response
        @response ||= Downloader.source_for url
      end

      def parsed
        @parsed ||= begin
          p = Scrapers.for response
          raise Errors::UnknownContent unless p
          p
        end
      end

      def assets
        @assets ||= begin
          parsed.assets.map do |(uri, name, type)|
            Models::Asset.new(merge_uri_with_page(uri), type)
          end
        end
      end

      def links
        @links ||= begin
          parsed.links.map do |(uri, name)|
            Models::Link.new(merge_uri_with_page(uri))
          end
        end
      end

  end
end

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
    rescue Addressable::URI::InvalidURIError => err
      return nil
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
            f_uri = merge_uri_with_page(uri)
            next unless f_uri
            Models::Asset.new(f_uri, type)
          end.compact
        end
      end

      def links
        @links ||= begin
          parsed.links.map do |(uri, name)|
            f_uri = merge_uri_with_page(uri)
            next unless f_uri
            Models::Link.new(f_uri)
          end.compact
        end
      end

  end
end

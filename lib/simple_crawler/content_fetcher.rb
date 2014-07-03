require 'addressable/uri'

module SimpleCrawler
  class ContentFetcher

    attr_accessor :url, :session

    def initialize(url, session)
      @url = url
      @session = session
    end

    def content_info
      @content_info ||= Models::ContentInfo.new(relative_uri, assets, links)
    end

    def merge_uri_with_page(uri)
      uri = Addressable::URI.parse(uri).normalize unless uri.is_a?(Addressable::URI)
      return session.relative_to(final_uri.join(uri).normalize)
    rescue Addressable::URI::InvalidURIError => err
      return nil
    end

    private

      def final_uri
        @final_uri ||= Addressable::URI.parse(response.final_uri.to_s)
      end

      def relative_uri
        @relative_uri ||= begin
          res = session.relative_to(final_uri)
          if res.relative? && res.path.empty? && res.fragment.empty?
            Addressable::URI.parse("/")
          else
            res
          end
        end
      end

      def response
        @response ||= Downloader.source_for session.absolute_uri_to url
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

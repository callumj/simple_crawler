require 'nokogiri'

module SimpleCrawler
  module Scrapers
    class CSS < Base

      EMPTY_LINKS = [].freeze
      REGEX = /url\(([^)]+)\)/

      attr_accessor :dl_resp

      def initialize(dl_resp)
        raise ArgumentError unless dl_resp.is_a?(Models::DownloadResponse)
        @dl_resp  = dl_resp
      end

      def links
        EMPTY_LINKS
      end

      def assets
        @assets ||= begin
          scan = StringScanner.new dl_resp.source

          list = []
          while scan.scan_until(REGEX) != nil
            matched = scan[1]
            next if matched.start_with?("data:")
            matched.gsub! /(^['"])|(['"]$)/, ""

            type = nil
            if matched.match(/\.css(\?|$|\/)/)
              type = "stylesheet"
            elsif matched.match(/\.(png|gif|jpg|jpeg|bmp|tiff|tif|pneg)(\?|$|\/)/)
              type = "img"
            elsif matched.match(/\.(eot|woff|ttf|svg)(\?|$|\/)/)
              type = "font"
            else
              type = "other"
            end

            list << [matched, type]
          end

          list
        end
      end
    end
  end
end

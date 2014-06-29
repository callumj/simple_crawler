require 'nokogiri'

module SimpleCrawler
  module Scrapers
    class HTML < Base

      attr_accessor :dl_resp, :document

      SUPPORTED_LINK_ASSETS = %w(stylesheet icon)
      SUPPORTED_LINK_LINKS = %w(canonical alternate external help archives)

      def initialize(dl_resp)
        raise ArgumentError unless dl_resp.is_a?(Models::DownloadResponse)
        @dl_resp  = dl_resp
        @document = Nokogiri::HTML(dl_resp.source)
      end

      def links
        @links ||= begin
          document.xpath("//a[@href]|//link[@href]").select do |node|
            next false if node["href"].nil? || node["href"].empty?
            next true if node["rel"].nil?
            SUPPORTED_LINK_LINKS.include?(node["rel"])
          end.map do |node|
            [node["href"], node.text.strip]
          end.uniq { |(href, text)| href }
        end
      end

      def assets
        @assets ||= begin
          document.xpath("//link[@href]|//img[@src]|//script[@src]").select do |node|
            next true if node["rel"].nil?
            SUPPORTED_LINK_ASSETS.include?(node["rel"])
          end.map do |node|
            [node["href"] || node["src"], node.text.strip]
          end.uniq { |(href, text)| href }
        end
      end
    end
  end
end

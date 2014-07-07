require 'nokogiri'

module SimpleCrawler
  module Scrapers

    # Utilises Nokogiri to scrape the contents of a HTML page for assets and links.

    class HTML < Base

      attr_accessor :dl_resp, :document

      SUPPORTED_LINK_ASSETS = %w(stylesheet icon)
      SUPPORTED_LINK_LINKS = %w(canonical alternate external help archives)

      def initialize(dl_resp)
        raise ArgumentError unless dl_resp.is_a?(Models::DownloadResponse)
        @dl_resp  = dl_resp
        @document = Nokogiri::HTML(dl_resp.source)
      end

      def title
        @title ||= @document.xpath("//title").text
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

      # Returns the assets utilised by the page making use of the CSS scraper for internal CSS stylsheets or styles.

      def assets
        @assets ||= begin
          base = extract_from_assets document

          document.xpath("//head/comment()").each do |node|
            text = node.text
            next if text.match(/<script/).nil?

            text.gsub! /\[if [A-Za-z0-9 ]+\]>[^<]+/, ""
            text.gsub! /<!\[endif\]/, ""
            mini_doc = Nokogiri::HTML.parse text
            base += extract_from_assets mini_doc
          end

          document.xpath("//style[@type='text/css']").each do |node|
            append_from_css node.text, base
          end

          document.xpath("//*[@style]").each do |node|
            append_from_css node["style"], base
          end
          
          base
        end
      end

      private

        def append_from_css(css_content, dest)
          mock_doc = Models::DownloadResponse.new(css_content, dl_resp.headers, dl_resp.status, dl_resp.final_uri)
          sc = CSS.new(mock_doc)
          dest.concat sc.assets
        end

        def extract_from_assets(doc)
          doc.xpath("//link[@href]|//img[@src]|//script[@src]").select do |node|
            next true if node["rel"].nil?
            SUPPORTED_LINK_ASSETS.include?(node["rel"])
          end.map do |node|
            type = node["rel"].nil? ? node.name : node["rel"]
            type = TypeHelper::ASSET_IMAGE_TYPE if type == "img"
            [node["href"] || node["src"], node.text.strip, type]
          end.uniq { |(href, text)| href }
        end
    end
  end
end

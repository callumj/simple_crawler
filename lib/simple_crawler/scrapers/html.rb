require 'nokogiri'

module SimpleCrawler
  module Scrapers
    class HTML

      attr_accessor :dl_resp, :document

      def initialize(dl_resp)
        raise ArgumentError unless dl_resp.is_a?(Models::DownloadResponse)
        @dl_resp  = dl_resp
        @document = Nokogiri::HTML(dl_resp.source)
      end

      def links
        @links ||=  begin
          node_set = document.xpath("//*[@href]").map do |node|
            [node["href"], node.text]
          end.uniq { |(href, text)| href }
        end
      end
    end
  end
end

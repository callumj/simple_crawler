module SimpleCrawler
  module Scrapers
    require 'simple_crawler/scrapers/base'
    require 'simple_crawler/scrapers/html'
    require 'simple_crawler/scrapers/css'

    def self.for(dl_req)
      content_type = dl_req.headers["Content-Type"]

      if content_type
        return Scrapers::HTML.new(dl_req) if content_type.include?("text/html")
      else
        return Scrapers::HTML.new(dl_req) if dl_req.source.include?("<!DOCTYPE html")
      end

      nil
    end
  end
end
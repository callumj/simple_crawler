module SimpleCrawler
  module Models
    class ContentInfo < Struct.new(:final_url, :assets, :links)

      class Asset < Struct.new(:url, :type); end
      class Link < Struct.new(:url); end

    end
  end
end

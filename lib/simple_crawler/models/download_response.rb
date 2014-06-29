module SimpleCrawler
  module Models
    class DownloadResponse < Struct.new(:source, :headers, :status, :final_uri)
    end
  end
end

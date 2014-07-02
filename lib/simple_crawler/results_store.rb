require 'json'

module SimpleCrawler
  class ResultsStore

    attr_reader :crawl_session, :contents

    def initialize(opts = {})
      @crawl_session = opts[:crawl_session]
      raise ArgumentError, "A CrawlSession is required!" unless @crawl_session.is_a?(CrawlSession)
      @contents = Set.new
    end

    def add_content(content_info)
      @contents << content_info
    end

    def dump(file_path)
      results = JSON.generate @contents.to_a
      File.open(file_path, "w+") do |f|
        f.write results
      end
    end

  end
end
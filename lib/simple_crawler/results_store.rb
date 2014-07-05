require 'json'

module SimpleCrawler
  class ResultsStore

    attr_reader :crawl_session
    attr_reader :contents, :assets_usage, :incoming_links

    def initialize(opts = {})
      @crawl_session = opts[:crawl_session]
      raise ArgumentError, "A CrawlSession is required!" unless @crawl_session.is_a?(CrawlSession)

      @contents = Set.new

      @assets_usage = Hash.new { |hash, key| hash[key] = Set.new }
      @incoming_links = Hash.new { |hash, key| hash[key] = Set.new }
    end

    def add_content(content_info)
      @contents << content_info
      content_info.assets.each { |asset| @assets_usage[asset.uri] << content_info.final_uri }
      content_info.links.each { |link| @incoming_links[link.uri] << content_info.final_uri }
    end

  end
end
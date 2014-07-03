require 'json'

module SimpleCrawler
  class ResultsStore

    attr_reader :crawl_session, :contents

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

    def dump(base_file_path)
      prefix = if base_file_path.end_with?("/")
        base_file_path
      else
        "#{base_file_path}_"
      end

      map_file = "#{prefix}map.json"
      generate_json_to_file @contents.to_a, map_file

      assets_file = "#{prefix}assets.json"
      generate_json_to_file generate_json_format(@assets_usage), assets_file

      links_file = "#{prefix}incoming_links.json"
      generate_json_to_file generate_json_format(@incoming_links), links_file
    end

    private

      def generate_json_to_file(contents, file)
        results = JSON.generate contents
        File.open(file, "w") do |f|
          f.write results
        end
      end

      def generate_json_format(hsh)
        hsh.sort_by { |(uri, set)| -set.length }.each_with_object({}) do |(uri, set), hash|
          hash[uri.to_s] = set.map(&:to_s)
        end
      end

  end
end
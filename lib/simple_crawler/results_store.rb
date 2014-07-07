require 'json'

module SimpleCrawler
  class ResultsStore

    attr_reader :crawl_session
    attr_reader :contents, :local_stylesheets, :assets_usage, :incoming_links, :title_map

    def initialize(opts = {})
      @crawl_session = opts[:crawl_session]
      raise ArgumentError, "A CrawlSession is required!" unless @crawl_session.is_a?(CrawlSession)

      @title_map = Hash.new { |hash, key| hash[key] = Hash.new }

      @contents = Set.new
      @local_stylesheets = Set.new

      @assets_usage = Hash.new { |hash, key| hash[key] = Set.new }
      @incoming_links = Hash.new { |hash, key| hash[key] = Set.new }

      @add_content_lock = Mutex.new
    end

    def add_content(content_info)
      @add_content_lock.synchronize do
        if content_info.stylesheet?
          @local_stylesheets << content_info
        else
          @contents << content_info
          record_title content_info
          attach_callback content_info
          content_info.links.each do |link|
            attach_callback link
            @incoming_links[link.uri] << content_info.final_uri
          end
        end

        content_info.assets.each { |asset| @assets_usage[asset.uri] << content_info.final_uri }
      end
    end

    def record_title(content_info)
      return if content_info.incoming_title.nil?

      key = title_key content_info
      sub_key = title_subkey content_info
      @title_map[key][sub_key] = content_info.incoming_title
    end

    def fetch_title(target)
      key = title_key target
      sub_key = title_subkey target
      @title_map[key][sub_key] || @title_map[key][:default]
    end

    def attach_callback(target)
      target.missing_title_callback = Proc.new do
        self.fetch_title target
      end
    end

    private

      def title_key(content_info)
        "#{content_info.uri.origin}#{content_info.uri.path}"
      end

      def title_subkey(content_info)
        query = content_info.uri.query
        fragment = content_info.uri.fragment
        return :default if query.nil? || query.empty?

        query
      end

  end
end
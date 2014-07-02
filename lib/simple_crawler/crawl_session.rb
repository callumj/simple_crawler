module SimpleCrawler
  class CrawlSession

    attr_reader :host_restriction, :output_file

    def initialize(opts = {})
      @host_restriction = opts[:host_restriction]
      @output_file      = opts[:output_file]
    end

    def valid_host?(uri)
      return false unless uri.scheme == "http" || uri.scheme == "https"
      return true unless host_restriction
      if host_restriction.is_a?(String)
        host_restriction.downcase == uri.host.downcase
      else
        host_restriction.match(uri.host.downcase) != nil
      end
    end

    def add_content(content_info)
      results_store.add_content content_info
      content_info.links.each do |l|
        queue.enqueue l.uri
      end
    end

    def queue
      @queue ||= GlobalQueue.new crawl_session: self
    end

    def results_store
      @results_store ||= ResultsStore.new crawl_session: self
    end

    def dump_results
      raise "Output file not specified" unless @output_file
      results_store.dump @output_file
    rescue Exception => err
      binding.pry
    end

  end
end

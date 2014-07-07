module SimpleCrawler

  # Represents a session for the lifetime of crawling, allows various services to query, store and ask questions about what to
  # do with crawled content

  class CrawlSession

    attr_reader :host_restriction, :output, :initial_url, :initial_uri
    attr_reader :storage

    # Initialize a instance providing a Hash of options
    #  * initial_url: The address to the first page to be crawled
    #  * host_restriction: The domain to restrict to, will be overridden by the domain found via initial_url
    #  * output: The directory to write the results to (will be created)

    def initialize(opts = {})
      @initial_url = opts[:initial_url]

      if @initial_url
        @initial_uri = Addressable::URI.parse(@initial_url).normalize

        if @initial_uri.path.empty?
          @initial_uri.path = "/"
        end

        @initial_url = @initial_uri.to_s
        opts[:host_restriction] = initial_uri.host
      end

      @host_restriction = opts[:host_restriction]
      @output           = opts[:output]
      @records_changed  = 0

      @sync_lock = Mutex.new
    end

    def relative_to(uri)
      if initial_uri.nil?
        return uri.is_a?(Addressable::URI) ? uri : Addressable::URI.parse(uri).normalize
      end
      initial_uri.route_to uri
    end

    def absolute_uri_to(uri)
      parsed = uri.is_a?(Addressable::URI) ? uri : Addressable::URI.parse(uri).normalize
      if initial_uri.nil?
        return parsed
      end
      initial_uri.join parsed
    end

    def valid_host?(uri)
      return true if uri.relative?
      return false unless uri.scheme == "http" || uri.scheme == "https"
      return true unless host_restriction
      if host_restriction.is_a?(String)
        host_restriction.downcase == uri.host.downcase
      else
        host_restriction.match(uri.host.downcase) != nil
      end
    end

    # Add a ContentInfo object to the results store

    def add_content(content_info)
      if results_store.contents.empty?
        if !content_info.final_uri.relative?
          @initial_uri = content_info.final_uri
          @host_restriction = @initial_uri.host
        end
      end

      results_store.add_content content_info
      content_info.links.each do |l|
        queue.enqueue l.uri
      end

      content_info.assets.each do |a|
        queue.enqueue a.uri if a.stylesheet?
      end

      @sync_lock.synchronize do
        @records_changed += 1
        flush = storage.records_changed @records_changed
        @records_changed = 0 if flush
      end
    end

    def queue
      @queue ||= GlobalQueue.new(crawl_session: self).tap do |q|
        q.enqueue initial_uri if initial_uri
      end
    end

    def results_store
      @results_store ||= ResultsStore.new crawl_session: self
    end

    def storage
      @storage ||= StorageAdapters::File.new crawl_session: self, output: @output
    end

    # Tell the storage adapter to sync

    def dump_results
      storage.sync
    end

    def notify_of_failure(dequeued_uri)

    end

    def info
      {
        initial_uri: @initial_uri
      }
    end

  end
end

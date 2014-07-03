require 'thread'

module SimpleCrawler
  class GlobalQueue

    class Node < Struct.new(:uri, :next); end

    attr_reader :crawl_session, :known_uris

    def initialize(opts = {})
      @crawl_session = opts[:crawl_session]
      raise ArgumentError, "A CrawlSession is required!" unless @crawl_session.is_a?(CrawlSession)
      @head = nil
      @tail = nil
      @mutex = Mutex.new
      @known_uris = Set.new
    end

    def valid_host?(uri)
      self.crawl_session.valid_host? uri
    end

    def visited_before?(uri)
      @known_uris.include? cleanse_uri(uri)
    end

    def can_enqueue?(uri)
      valid_host?(uri) && !visited_before?(uri)
    end

    def peek
      @mutex.synchronize { @head && @head.uri }
    end

    def enqueue(uri)
      res = @mutex.synchronize do
        next false unless can_enqueue? uri

        clean = cleanse_uri(uri)
        next false if clean.empty?
        @known_uris << clean
        if @head.nil?
          @head = Node.new(uri)
          @tail = @head
        else
          @tail.next = Node.new(uri)
          @tail = @tail.next
        end

        next true
      end

      res
    end

    def dequeue
      fetched = nil
      @mutex.synchronize do
        next nil unless @head
      
        fetched = @head
        unless fetched.nil?
          @head = fetched.next
        end

        @tail = nil if @head == nil
      end
      return nil unless fetched

      fetched.uri
    end

    private

      def cleanse_uri(uri)
        cleansed = uri.to_s.dup
        cleansed.gsub!("##{uri.fragment}", "") if uri.fragment
        cleansed
      end

  end
end
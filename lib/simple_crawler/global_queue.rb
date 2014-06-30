require 'thread'

module SimpleCrawler
  class GlobalQueue

    class Node < Struct.new(:uri, :next); end

    def self.setup_instance!(opts = {})
      @@instance = new(opts)
    end

    def self.flush_instance!
      @@instance = nil
    end

    def self.instance
      if defined?(@@instance)
        @@instance
      else
        nil
      end
    end

    attr_reader :host_restriction, :known_uris

    def initialize(opts = {})
      raise Errors::InstanceAlreadyRunning if self.class.instance
      @host_restriction = opts[:host_restriction]
      @head = nil
      @tail = nil
      @mutex = Mutex.new
      @known_uris = Set.new
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

        @known_uris << cleanse_uri(uri)
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
        cleansed = uri.to_s
        cleansed.gsub!("##{uri.fragment}", "") if uri.fragment
        cleansed
      end

  end
end
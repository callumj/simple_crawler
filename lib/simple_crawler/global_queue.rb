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
      @known_uris = Set.new
    end

    def valid_host?(uri)
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
      @head && @head.uri
    end

    def enqueue(uri)
      return false unless can_enqueue? uri

      @known_uris << cleanse_uri(uri)
      if @head.nil?
        @head = Node.new(uri)
        @tail = @head
      else
        @tail.next = Node.new(uri)
        @tail = @tail.next
      end

      true
    end

    def dequeue
      return unless @head

      fetched = @head
      unless fetched.nil?
        @head = fetched.next
      end

      @tail = nil if @head == nil

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
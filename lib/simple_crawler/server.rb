require 'socket'
require 'thread'

module SimpleCrawler
  class Server

    FINISH_STR = "!FIN!"

    DEFAULT_PORT = 9018
    SHUTDOWN_AFTER_EMPTY_FOR = 100
    SLEEP_FOR = 0.1

    attr_reader :crawl_session
    attr_reader :host, :port, :server, :active, :active_connections, :awaiting_uris

    attr_reader :serve_thread, :monitor_thread

    def initialize(opts = {})
      @crawl_session = opts[:crawl_session]
      raise ArgumentError, "A CrawlSession is required!" unless @crawl_session.is_a?(CrawlSession)

      if opts[:listen] && !opts[:listen].empty?
        split = opts[:listen].split ":"
        @host = split[0] if split.length > 1 && !split[0].empty?
        @port = split.last && split.last.to_i      
      end

      @port ||= DEFAULT_PORT
      @host ||= "0.0.0.0"

      @server = TCPServer.new @host, @port
      @active = true

      @active_connections = Set.new
      @count_lock = Mutex.new
      @empty_for = 0

      @awaiting_uris = Set.new
      @dequeue_lock = Mutex.new
    end

    def active?
      @active == true
    end

    def run
      @serve_thread = Thread.new { serve }
      @monitor_thread = Thread.new { monitor_for_shutdown }
    end

    def serve
      while active?
        client = server.accept
        Thread.new { process client }
      end
    end

    def shutdown!
      @server.close_read
      @active = false
      @crawl_session.dump_results
    end

    def monitor_for_shutdown
      while active?
        empty = crawl_session.queue.peek == nil && @awaiting_uris.empty?
        if empty
          if @empty_for >= SHUTDOWN_AFTER_EMPTY_FOR
            shutdown!
            return
          else
            @empty_for += 1
          end
        end

        sleep SLEEP_FOR
      end
    end

    def process(socket)
      @count_lock.synchronize { @active_connections << Thread.current }
      while resp = socket.gets
        data = resp
        until (more = socket.gets).strip == FINISH_STR
          data << more
        end

        begin
          message = Marshal.load(data)
        rescue
          puts data
          next
        end
        resp = handle_message message
        next if resp.nil?
        if resp == :close
          socket.close
          break
        else
          packed = Marshal.dump(resp)
          socket.puts packed
          socket.puts FINISH_STR
        end
      end
      @count_lock.synchronize { @active_connections.delete Thread.current }
    rescue StandardError => err
      SimpleCrawler.logger.error err.inspect
    end

    def handle_message(message)
      if message.operation == "info"
        return Client::Response.new(crawl_session.info)
      elsif message.operation == "add_content"
        @dequeue_lock.synchronize { @awaiting_uris.delete message.object.original_uri.to_s }
        crawl_session.add_content message.object
        return true
      elsif message.operation == "peek"
        return Client::Response.new(crawl_session.queue.peek)
      elsif message.operation == "ignore"
        @dequeue_lock.synchronize { @awaiting_uris.delete message.object.to_s }
      elsif message.operation == "dequeue"
        deq = crawl_session.queue.dequeue
        @dequeue_lock.synchronize { @awaiting_uris << deq.to_s } unless deq.nil?
        return Client::Response.new(deq)
      elsif message.operation == "close"
        return :close
      end
      true
    end

  end
end
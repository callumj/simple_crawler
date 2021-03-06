require 'addressable/uri'

module SimpleCrawler
  module Tasks
    class MultiWorker

      class Supervisor

        MAX_WORKERS = 50
        SLEEP_FOR = 0.0001

        attr_accessor :run_forever
        attr_reader :session, :main_thread

        def initialize(session)
          @session = session
          @active_workers = []
          @active = true
        end

        def run
          @main_thread = Thread.new { self.keep_alive }
        end

        def max_workers
          @max_workers ||= !ENV["MAX_WORKERS"].nil? && !ENV["MAX_WORKERS"].empty? && ENV["MAX_WORKERS"].to_i || MAX_WORKERS
        end

        def keep_alive
          while (@active && session.queue.peek != nil) || any_active_workers? || (@active && run_forever)
            clean_dead_workers
            if session.queue.peek != nil && @active
              workers_to_start = max_workers - @active_workers.length
              workers_to_start.times do |i|
                SimpleCrawler.logger.debug "Spawning worker #{i}"
                @active_workers << Thread.new { Worker.new.perform(session) }
              end
            end

            sleep SLEEP_FOR
          end

          SimpleCrawler.logger.info "Crawl completed. Dumping results"
          session.dump_results
        end

        def any_active_workers?
          @active_workers.any? { |t| good_worker?(t) }
        end

        def clean_dead_workers
          @active_workers.select! { |t| good_worker?(t) }
        end

        def num_active_workers
          @active_workers.length
        end

        def good_worker?(t)
          t.status == "sleep" || t.status == "run"
        end

        def shutdown!
          @active = false
          Thread.new { SimpleCrawler.logger.warn "Shutdown received, waiting for workers to finish." }
        end

      end

      def self.run(initial_url, output_file)
        session = CrawlSession.new initial_url: initial_url, output: output_file
        s = Supervisor.new session
        s.run
        s
      end

      def self.client(host, port)
        connection = Client::Connection.new port, host
        session = Client::CrawlSession.new connection
        s = Supervisor.new session
        s.run_forever = true
        s.run
        s
      end
    end
  end
end

require 'addressable/uri'

module SimpleCrawler
  module Tasks
    class MultiWorker

      class Supervisor

        MAX_WORKERS = 50
        SLEEP_FOR = 0.0001

        attr_accessor :session, :main_thread

        def initialize(session)
          @session = session
          @active_workers = []
        end

        def run
          @main_thread = Thread.new { self.keep_alive }
        end

        def keep_alive
          while session.queue.peek != nil || @active_workers.any? { |t| good_worker?(t) }
            clean_dead_workers
            if session.queue.peek != nil
              workers_to_start = MAX_WORKERS - @active_workers.length
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

        def clean_dead_workers
          @active_workers.select! { |t| good_worker?(t) }
        end

        def num_active_workers
          @active_workers.length
        end

        def good_worker?(t)
          t.status == "sleep" || t.status == "run"
        end

      end

      def self.run(initial_url, output_file)
        session = CrawlSession.new initial_url: initial_url, output_file: output_file
        s = Supervisor.new session
        s.run
        s
      end
    end
  end
end

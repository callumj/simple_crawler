require 'addressable/uri'
require 'thread'

module SimpleCrawler
  module Tasks
    class MultipleWorkers

      MAX_WORKERS = 25

      def self.run(initial_uri)
        parsed = Addressable::URI.parse initial_uri
        SimpleCrawler::GlobalQueue.flush_instance!

        SimpleCrawler::GlobalQueue.setup_instance! host_restriction: parsed.host
        SimpleCrawler::GlobalQueue.instance.enqueue parsed

        MultipleWorkers.new.spawn
      end

      attr_accessor :running_workers

      def initialize
        self.running_workers = 0
        @mutex = Mutex.new
      end

      def spawn
        amount_to_spawn = 0
        @mutex.synchronize do
          next if self.running_workers == MAX_WORKERS || SimpleCrawler::GlobalQueue.instance.peek == nil
          amount_to_spawn = MAX_WORKERS - self.running_workers
        end
        return if amount_to_spawn == 0

        amount_to_spawn.times { |i| Thread.new { run } }
      end

      def run
        @mutex.synchronize do
          self.running_workers += 1
        end

        begin
          SimpleCrawler::Worker.new.perform
        end

        @mutex.synchronize do
          self.running_workers -= 1
        end

        spawn
      end
    end
  end
end

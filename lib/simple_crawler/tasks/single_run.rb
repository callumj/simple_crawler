require 'addressable/uri'

module SimpleCrawler
  module Tasks
    class SingleRun

      def self.run(initial_uri)
        parsed = Addressable::URI.parse initial_uri
        SimpleCrawler::GlobalQueue.setup_instance! host_restriction: parsed.host
        SimpleCrawler::GlobalQueue.instance.enqueue parsed
        while SimpleCrawler::GlobalQueue.instance.peek != nil
          SimpleCrawler::Worker.new.perform
        end
        SimpleCrawler::GlobalQueue.flush_instance!
      end
    end
  end
end

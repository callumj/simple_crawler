require 'addressable/uri'

module SimpleCrawler
  module Tasks
    class SingleRun

      def self.run(initial_url, output_file)
        session = CrawlSession.new initial_url: initial_url, output_file: output_file
        while session.queue.peek != nil
          SimpleCrawler::Worker.new.perform session
        end
        session.dump_results
      end
    end
  end
end

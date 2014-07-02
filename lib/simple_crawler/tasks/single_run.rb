require 'addressable/uri'

module SimpleCrawler
  module Tasks
    class SingleRun

      def self.run(initial_uri, output_file)
        parsed = Addressable::URI.parse initial_uri
        session = CrawlSession.new host_restriction: parsed.host, output_file: output_file
        session.queue.enqueue parsed
        while session.queue.peek != nil
          SimpleCrawler::Worker.new.perform session
        end
        session.dump_results
      end
    end
  end
end

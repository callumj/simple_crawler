module SimpleCrawler
  module Tasks
    class ServerOnly

      def self.run(initial_url, output_file)
        session = CrawlSession.new initial_url: initial_url, output: output_file
        
        server = Server.new crawl_session: session
        server.run
        server
      end
    end
  end
end

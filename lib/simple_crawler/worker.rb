module SimpleCrawler
  class Worker

    def perform(session)
      target_uri = session.queue.dequeue
      return unless target_uri
      STDOUT.puts "Processing #{target_uri.to_s}"
      content = ContentFetcher.new(target_uri)
      res = content.content_info
      session.add_content res
    rescue Errors::UnknownContent
      STDOUT.puts "\tDo not know how to handle this."
    end

  end
end

module SimpleCrawler
  class Worker

    def perform
      target_uri = GlobalQueue.instance.dequeue
      return unless target_uri
      STDOUT.puts "Processing #{target_uri.to_s}"
      content = ContentFetcher.new(target_uri)
      res = content.content_info
      res.links.each do |l|
        GlobalQueue.instance.enqueue l.url
      end
    rescue Errors::UnknownContent
      STDOUT.puts "\tDo not know how to handle this."
    end

  end
end

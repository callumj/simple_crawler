module SimpleCrawler

  # Interacts with a session to take the top of a queue and process it, adding it back to the session on success.

  class Worker

    def perform(session)
      target_uri = session.queue.dequeue
      return unless target_uri
      begin
        SimpleCrawler.logger.debug "Processing #{target_uri.to_s}"
        content = ContentFetcher.new(target_uri, session)
        res = content.content_info
        session.add_content res
      rescue Errors::UnknownContent
        session.notify_of_failure target_uri
        SimpleCrawler.logger.debug "\tDo not know how to handle this."
      rescue StandardError => err
        session.notify_of_failure(target_uri) if target_uri
        SimpleCrawler.logger.error "Encountered error: #{err.to_s}"
      end
    end

  end
end

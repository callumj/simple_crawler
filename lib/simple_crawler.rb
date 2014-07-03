module SimpleCrawler
  require 'simple_crawler/errors'
  require 'simple_crawler/utils'

  require 'simple_crawler/models'

  require 'simple_crawler/crawl_session'

  require 'simple_crawler/results_store'
  require 'simple_crawler/global_queue'
  require 'simple_crawler/downloader'
  require 'simple_crawler/scrapers'
  require 'simple_crawler/content_fetcher'
  require 'simple_crawler/worker'

  require 'simple_crawler/tasks'

  require 'logger'

  def self.log_to=(val)
    @@log_to = val
  end

  def self.log_to
    if defined?(@@log_to)
      @@log_to
    else
      ENV["LOG"]
    end
  end

  def self.logger
    @@logger ||= begin
      log_source = if log_to
        log_to.downcase == "NONE" ? nil : File.open(log_to, "w+")
      else
        STDOUT
      end

      Logger.new log_source
    end
  end
end
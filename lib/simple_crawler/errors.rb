module SimpleCrawler
  module Errors
    class Error < StandardError; end

    class UnknownContent < Error; end

    class InstanceAlreadyRunning < Error; end
  end
end
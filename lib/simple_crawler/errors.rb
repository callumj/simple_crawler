module SimpleCrawler
  module Errors
    class Error < StandardError; end

    class UnknownContent < Error; end
  end
end
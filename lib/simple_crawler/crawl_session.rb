module SimpleCrawler
  class CrawlSession

    attr_reader :host_restriction

    def initialize(opts = {})
      @host_restriction = opts[:host_restriction]
    end

    def valid_host?(uri)
      return false unless uri.scheme == "http" || uri.scheme == "https"
      return true unless host_restriction
      if host_restriction.is_a?(String)
        host_restriction.downcase == uri.host.downcase
      else
        host_restriction.match(uri.host.downcase) != nil
      end
    end

  end
end

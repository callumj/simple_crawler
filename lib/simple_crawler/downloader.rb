require 'zlib'
require 'faraday'
require 'faraday_middleware'
require 'addressable/uri'

module SimpleCrawler
  class Downloader

    MAX_ZLIB_ERROR = 2
    MAX_FARADAY_ERROR = 6
    SLEEP_AFTER = 1
    SLEEP_SQUARE_AFTER = 3
    SLEEP_MULT = 0.02

    attr_accessor :url

    def self.source_for(potential_url)
      new(potential_url).obtain_source
    end

    def initialize(potential_url)
      @url = potential_url
    end

    # Will fetch the source from a web server, following the redirects and handling server errors.

    def obtain_source
      try_count = 0
      header_options = {}
      begin
        try_count += 1
        resp = connection.get(request_location) do |r|
          if header_options.keys.length != 0
            header_options.each { |k,v| r.headers[k] = v }
          end
        end

        source = resp.body

        if source.encoding.name.downcase.include?("ascii")
          source = source.force_encoding("utf-8")
        end

        return Models::DownloadResponse.new(source, resp.headers, resp.status, resp.env.url)
      rescue Faraday::Error => err
        raise err if try_count >= MAX_FARADAY_ERROR

        if try_count > SLEEP_AFTER
          base_multiplier = try_count > SLEEP_SQUARE_AFTER ? try_count.to_f * try_count.to_f : try_count.to_f
          sleep(base_multiplier * SLEEP_MULT)
        end

        retry
      rescue Zlib::DataError => err
        raise err if try_count >= MAX_ZLIB_ERROR

        header_options = {
          accept_encoding: 'none'
        }
        retry
      end
    end

    private

      def parsed_uri
        @parsed_uri ||= Addressable::URI.parse(url).normalize
      end

      def connection
        @connection ||= Faraday.new(parsed_uri.site) do |b|
          b.use FaradayMiddleware::FollowRedirects, limit: 10
          b.adapter :net_http
        end
      end

      def request_location
        @request_location ||= parsed_uri.request_uri
      end

  end
end

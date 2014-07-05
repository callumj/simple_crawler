require 'fileutils'
require 'cgi'

module SimpleCrawler
  module StorageAdapters
    class File < Base

      XML_HEAD = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>".freeze

      attr_accessor :output_directory

      def initialize(opts = {})
        super opts
        @output_directory = opts[:output]
        unless Dir.exists?(@output_directory)
          FileUtils.mkdir_p @output_directory
        end
      end

      def sync
        dump
      end

      def finish_up
        dump
      end

      def dump
        map_file = "#{output_directory}/map.xml"
        generate_file results_store.contents.to_a, map_file

        style_file = "#{output_directory}/local_stylesheets.xml"
        generate_file results_store.local_stylesheets.to_a, style_file

        assets_file = "#{output_directory}/assets.xml"
        generate_file generate_format(results_store.assets_usage), assets_file

        links_file = "#{output_directory}/incoming_links.xml"
        generate_file generate_format(results_store.incoming_links), links_file
      end

      def generate_file(contents, file)
        root = build_xml contents
        ::File.open(file, "wb") do |f|
          f.write root
        end
      end

      def build_xml(obj, name = "item")
        buf = StringIO.new XML_HEAD.dup

        if obj.respond_to?(:as_json)
          obj = obj.as_json
        end

        res = if obj.is_a?(Array)
          produce_array obj, name
        elsif obj.is_a?(Hash)
          produce_hash obj, name
        else
          produce_element obj.to_s, name
        end

        buf.write res

        buf.seek 0
        buf.string
      end

      private

        def produce_hash(obj, tag = "item")
          buf = StringIO.new

          if obj[:id] != nil
            buf.write "<#{tag} id=\"#{CGI.escapeHTML(obj[:id])}\">"
          else
            buf.write "<#{tag}>"
          end

          obj.each do |key, value|
            if value.respond_to?(:as_json)
              value = value.as_json
            end

            if value.is_a?(Hash)
              buf.write produce_hash(value, key.to_s)
            elsif value.is_a?(Array)
              buf.write produce_array(value, key.to_s)
            else
              buf.write produce_element(value.to_s, key.to_s)
            end
          end

          buf.write "</#{tag}>"

          buf.seek 0
          buf.string
        end

        def produce_array(ary, tag = "item")
          buf = StringIO.new

          inf = build_root_information tag
          buf.write "<#{inf[:root]}>"

          ary.each do |item|
            next if item.nil?

            if item.respond_to?(:as_json)
              item = item.as_json
            end

            if item.is_a?(Hash)
              buf.write produce_hash(item, inf[:tag])
            elsif item.is_a?(Array)
              buf.write produce_array(item, inf[:tag])
            else
              buf.write produce_element(item.to_s, inf[:tag])
            end
          end

          buf.write "</#{inf[:root]}>"

          buf.seek 0
          buf.string
        end

        def produce_element(text, tag = "item")
          encoded_text = if text.match(/[&<]/)
            "<![CDATA[#{text}]]>"
          else
            text
          end
          "<#{tag}>#{encoded_text}</#{tag}>"
        end

        def build_root_information(tag)
          tag = tag.dup
          tag[-1] = "" if tag[-1] == "s"
          {
            root: "#{tag}s",
            tag: tag
          }
        end

        def generate_format(hsh)
          hsh.sort_by { |(uri, set)| -set.length }.each_with_object({}) do |(uri, set), hash|
            hash[uri.to_s] = set.map(&:to_s)
          end
        end

    end
  end
end

require 'fileutils'
require 'cgi'

module SimpleCrawler
  module StorageAdapters
    class File < Base

      XML_HEAD = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>"

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

        assets_file = "#{output_directory}/assets.xml"
        generate_file generate_format(results_store.assets_usage), assets_file

        links_file = "#{output_directory}/incoming_links.xml"
        generate_file generate_format(results_store.incoming_links), links_file
      end

      def generate_file(contents, file)
        root = build_xml contents
        ::File.open(file, "w") do |f|
          f.write root
        end
      end

      def build_xml(obj, name = "item", root = true)
        name[-1] = "" if name[-1] == "s"
        buf = StringIO.new
        buf << XML_HEAD if root
        buf << "<#{name}_set>"
        obj.each do |(item_or_key, possible_hsh_value)|
          enum = possible_hsh_value || item_or_key
          if enum.respond_to?(:as_json)
            enum = enum.as_json
          end

          id_val = nil
          if item_or_key.is_a?(String) || item_or_key.is_a?(Symbol)
            id_val = item_or_key.to_s
          else
            id_val = enum[:id]
          end

          if id_val.nil?
            buf << "<#{name}>"
          else
            buf << "<#{name} id=\"#{CGI.escapeHTML(id_val)}\">"
          end

          if enum.is_a?(Array)
            buf << "<children>"
            enum.each do |val|
              buf << "<child>#{CGI.escapeHTML(val)}</child>"
            end
            buf << "</children>"
          elsif enum.is_a?(String)
             buf << "#{CGI.escapeHTML(enum)}" 
          else
            enum.each do |key, val|
              next if key == :id
              if val.is_a?(String)
                if val.match(/[&<]/)
                  buf << "<#{key}><![CDATA[#{val}]]></#{key}>"
                else
                  buf << "<#{key}>#{val}</#{key}>"
                end
              elsif !val.nil?
                res = build_xml val, key.to_s, false
                buf << res
              end
            end
          end
          buf << "</#{name}>"
        end
        buf << "</#{name}_set>"
        buf.seek 0
        buf.read
      end

      private

        def generate_format(hsh)
          hsh.sort_by { |(uri, set)| -set.length }.each_with_object({}) do |(uri, set), hash|
            hash[uri.to_s] = set.map(&:to_s)
          end
        end

    end
  end
end

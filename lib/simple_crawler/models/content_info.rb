require 'json'

module SimpleCrawler
  module Models
    class ContentInfo

      attr_accessor :final_uri, :assets, :links

      def initialize(final_uri, incoming_assets = nil, incoming_links = nil)

        self.final_uri = final_uri
        @assets = Utils.set_from_possible_array incoming_assets, Asset
        @links = Utils.set_from_possible_array incoming_links, Link
      end

      def add_links(link_or_ary)
        add_object_type :links, Link, link_or_ary
      end

      def add_assets(ass_or_ary)
        add_object_type :assets, Asset, ass_or_ary
      end

      def as_json
        {
          id:     final_uri.to_s,
          uri:    final_uri.to_s,
          assets: assets.map(&:as_json),
          links:  links.map(&:as_json)
        }
      end

      def to_json(obj)
        as_json.to_json(obj)
      end

      def stylesheet?
        final_uri.path.match(/\.css$/)
      end

      private

        def add_object_type(target_attr, type, obj_or_ary)
          ivar = instance_variable_get :"@#{target_attr}"
          if obj_or_ary.is_a?(type)
            ivar << obj_or_ary
          else
            ivar.merge obj_or_ary
          end
        end

    end
  end
end

require 'mime-types'

module SimpleCrawler
  class TypeHelper

    ASSET_IMAGE_TYPE = "image".freeze
    ASSET_STYLESHEET_TYPE = "stylesheet".freeze
    ASSET_FONT_TYPE = "font".freeze
    ASSET_JS_TYPE = "javascript".freeze

    BANNED_DOWNLOAD_MEDIA_TYPES = Set.new(["application", "video", "audio", "imae"])

    def self.can_be_downloaded?(name)
      lookups = mime_types_for name
      return true if lookups.empty?

      return !lookups.any? { |l| BANNED_DOWNLOAD_MEDIA_TYPES.include?(l.media_type) }
    end

    def self.type_from_name(name)
      return unless name

      return ASSET_STYLESHEET_TYPE if name.match(/\.css$/)
      return ASSET_JS_TYPE if name.match(/\.js$/)

      mime = mime_types_for name
      mime.each do |m|
        if m.raw_sub_type.start_with?("font")
          return ASSET_FONT_TYPE
        elsif m.raw_media_type == "image"
          return ASSET_IMAGE_TYPE
        end
      end

      if name.match(/\.(png|gif|jpg|jpeg|bmp|tiff|tif|pneg|svg)$/)
        return ASSET_IMAGE_TYPE
      elsif name.match(/\.(eot|woff|ttf|otf)$/)
        return ASSET_FONT_TYPE
      end
      nil
    end

    def self.mime_types_for(name)
      ext_part = name.match(/\.([A-Za-z0-9]+)$/)
      return [] unless ext_part && ext_part[1]
      MIME::Types.type_for(".#{ext_part[1]}")
    end

  end
end
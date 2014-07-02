module SimpleCrawler
  module Utils

    def self.set_from_possible_array(obj, expected_type = nil)
      if obj.is_a?(Set)
        obj
      elsif obj.is_a?(Array)
        Set.new(obj)
      else
        Set.new.tap do |s|
          if expected_type && s.is_a?(expected_type)
            s << obj
          end
        end
      end
    end

  end
end

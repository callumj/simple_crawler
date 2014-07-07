module SimpleCrawler
  module Client
    class Response

      attr_accessor :object

      def initialize(incoming_object)
        @object = incoming_object
      end

    end
  end
end

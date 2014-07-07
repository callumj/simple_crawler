module SimpleCrawler
  module Client
    class Message

      attr_accessor :operation, :object

      def initialize(incoming_operation, incoming_object)
        @operation = incoming_operation
        @object = incoming_object
      end

    end
  end
end

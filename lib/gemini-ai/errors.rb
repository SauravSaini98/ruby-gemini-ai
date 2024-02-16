module GeminiAi
  module Errors
    class GeminiAiError < StandardError; end
    class MissingProjectIdError < GeminiAiError; end
    class UnsupportedServiceError < GeminiAiError; end
    class BlockWithoutServerSentEventsError < GeminiAiError; end

    class RequestError < GeminiAiError
      attr_reader :request, :payload

      def initialize(message = nil, request: nil, payload: nil)
        @request = request
        @payload = payload
        super(message)
      end
    end
  end
end

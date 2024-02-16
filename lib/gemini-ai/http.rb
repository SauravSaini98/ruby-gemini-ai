require "event_stream_parser"

require_relative "http_headers"

module GeminiAi
  module HTTP
    include HTTPHeaders

    def json_post(path:, parameters:, &callback)
      conn.post(path) do |req|
        configure_json_post_request(req, parameters, &callback)
      end&.body
    end

    private

    def parse_json(response)
      return unless response
      return response unless response.is_a?(String)

      # Convert a multiline string of JSON objects to a JSON array.
      response = response.gsub("}\n{", "},{").prepend("[").concat("]")

      JSON.parse(response)
    end

    #===================================================================================================

    def to_json_stream(&callback)
      partial_json = ''
      parser = EventStreamParser::Parser.new

      proc do |chunk, bytes, env|
        if env && env.status != 200
          raise_error = Faraday::Response::RaiseError.new
          raise_error.on_complete(env.merge(body: chunk))
        end

        parser.feed(chunk) do |type, data, id, reconnection_time|
          partial_json += data
          parsed_json = parse_partial_json(partial_json)

          if parsed_json
            parsed_json_text = extract_text_from_json(parsed_json)
            result = {
              text: parsed_json_text,
              event: parsed_json,
              parsed: { type: type, data: data, id: id, reconnection_time: reconnection_time },
              raw: { chunk: chunk, bytes: bytes, env: env }
            }

            callback.call(result[:text], result[:event], result[:parsed], result[:raw]) unless callback.nil?

            partial_json = ''

            if parsed_json['candidates']
              parsed_json['candidates'].find do |candidate|
                !candidate['finishReason'].nil? && candidate['finishReason'] != ''
              end
            end

          end
        end
      end
    end

    def extract_text_from_json(parsed_json)
      parsed_json["candidates"].map do |candidate|
        candidate["content"]["parts"].map { |part| part["text"] }
      end.join(" ")
    end

    def parse_partial_json(response)
      return unless response
      return response unless response.is_a?(String)
      response.to_s.lstrip.start_with?('{', '[') ? JSON.parse(response) : nil
    rescue JSON::ParserError
      nil
    end

    #===================================================================================================

    def conn(multipart: false)
      connection = Faraday.new do |f|
        f.options[:timeout] = @request_timeout
        f.request(:multipart) if multipart
        f.use MiddlewareErrors
        f.response :raise_error
        f.response :json
      end

      @faraday_middleware&.call(connection)

      connection
    end

    def configure_json_post_request(req, parameters, &callback)
      req_parameters = parameters.dup
      if req.params["alt"].eql?("sse")
        req.options.on_data = to_json_stream(&callback)
      elsif req.params["alt"]
        raise ArgumentError, "The alt parameter value must be a sse"
      end

      req.headers = headers
      req.body = req_parameters.to_json
    end

    def try_parse_json(maybe_json)
      JSON.parse(maybe_json)
    rescue JSON::ParserError
      maybe_json
    end
  end
end



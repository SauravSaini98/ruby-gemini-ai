require "faraday"

require_relative "gemini-ai/http"
require_relative "gemini-ai/client"
require_relative "gemini-ai/errors"
require_relative "gemini-ai/version"

module GeminiAi
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class MiddlewareErrors < Faraday::Middleware
    def call(env)
      @app.call(env)
    rescue Faraday::Error => e
      raise e unless e.response.is_a?(Hash)

      logger = Logger.new($stdout)
      logger.formatter = proc do |_severity, _datetime, _progname, msg|
        "\033[31mGemini AI HTTP Error (spotted in ruby-gemini-ai #{VERSION}): #{msg}\n\033[0m"
      end
      logger.error(e.response[:body])

      raise e
    end
  end

  class Configuration
    attr_writer :api_key, :region, :file_path, :version, :service
    DEFAULT_SERVICE_VERSION = 'v1'.freeze
    DEFAULT_SERVICE = 'generative-language-api'.freeze

    def initialize
      @api_key = nil
      @region = nil
      @file_path = nil
      @version = DEFAULT_SERVICE_VERSION
      @service = DEFAULT_SERVICE
    end

    def api_key
      @api_key
    end

    def service
      unless %w[vertex-ai-api generative-language-api].include?(@service)
        raise Errors::UnsupportedServiceError, "Unsupported service: #{@service}"
      end
      @service
    end

    def version
      @version
    end

    def file_path
      @file_path
    end

    def region
      @region
    end

  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= GeminiAi::Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.parsed_response(response, join_val: " ")
    response.flat_map do |entry|
      entry["candidates"].map do |candidate|
        candidate.dig("content", "parts").map { |part| part["text"] }.join(join_val)
      end
    end.join(join_val)
  end

end

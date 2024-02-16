# frozen_string_literal: true

require 'event_stream_parser'
require 'faraday'
require 'json'
require 'googleauth'
require 'uri'

require_relative 'errors'

module GeminiAi
  class Client
    include GeminiAi::HTTP

    CONFIG_KEYS = %i[ api_key region file_path version service ].freeze
    attr_accessor :authentication, :authorizer, :project_id, :service_version
    attr_reader *CONFIG_KEYS, :faraday_middleware

    def initialize(config = {}, &faraday_middleware)
      CONFIG_KEYS.each do |key|
        # Set instance variables like service authentication etc
        instance_variable_set("@#{key}", config[key] || GeminiAi.configuration.send(key))
      end
      @service_version = @version || DEFAULT_SERVICE_VERSION
      case
      when @api_key
        @authentication = :api_key
      when @file_path
        @authentication = :service_account
        @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: File.open(@file_path),
          scope: 'https://www.googleapis.com/auth/cloud-platform'
        )
      else
        @authentication = :default_credentials
        @authorizer = Google::Auth.get_application_default
      end

      if @authentication == :service_account || @authentication == :default_credentials
        @project_id = @authorizer.project_id || @authorizer.quota_project_id
        raise Errors::MissingProjectIdError, 'Could not determine project_id, which is required.' if @project_id.nil?
      end
      @faraday_middleware = faraday_middleware
    end

    def stream_generate_content(payload, model: nil, stream: nil, &callback)
      path = build_request_url('streamGenerateContent', model, stream)
      json_post(path: path, parameters: payload, &callback)
    end

    def generate_content(payload, model: nil, stream: nil, &callback)
      path = build_request_url('generateContent', model, stream)
      json_post(path: path, parameters: payload, &callback)
    end

    private

    def build_request_url(path, model, stream)
      base_url = case @service
                 when 'vertex-ai-api'
                   "https://#{@region}-aiplatform.googleapis.com/#{service_version}/projects/#{@project_id}/locations/#{@region}/publishers/google/models/#{model}"
                 when 'generative-language-api'
                   "https://generativelanguage.googleapis.com/#{service_version}/models/#{model}"
                 end

      params = {}
      params[:alt] = 'sse' if stream
      params[:key] = @api_key if @authentication == :api_key

      uri = URI("#{base_url}:#{path}")
      uri.query = URI.encode_www_form(params) if params.present?
      uri.to_s
    end

  end
end

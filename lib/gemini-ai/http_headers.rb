module GeminiAi
  module HTTPHeaders

    private

    def headers
      default_headers = {
        "Content-Type" => "application/json"
      }
      if @authentication == :service_account || @authentication == :default_credentials
        default_headers.merge!("Authorization": "Bearer #{@authorizer.fetch_access_token!['access_token']}")
      end
      default_headers
    end
  end
end

# Ruby GeminiAi

This guide explains how to seamlessly integrate the powerful Gemini AI API into your Ruby projects. Utilize Gemini's cutting-edge language capabilities for generating text, translating languages, and more.

# Table of Contents

- [Installation](#installation)
  - [Bundler](#bundler)
  - [Gem Install](#gem-install)
- [Credentials](#credentials)
  - [Option 1: API Key (Generative Language API)](#option-1-api-key-generative-language-api)
  - [Option 2: Service Account Credentials File (Vertex AI API)](#option-2-service-account-credentials-file-vertex-ai-api)
  - [Option 3: Application Default Credentials (Vertex AI API)](#option-3-application-default-credentials-vertex-ai-api)
- [Usage](#usage)
  - [Quickstart](#quickstart)
  - [With Config](#with-config)
  - [Verbose Logging](#verbose-logging)
- [Methods](#methods)
  - [stream_generate_content](#stream_generate_content)
  - [generate_content](#generate_content)
- [Development](#development)
- [Compatibility](#compatibility)
- [License](#license)
- [Resources and References](#resources-and-references)
- [Additional Notes](#additional-notes)

## Installation

### Bundler

Add this line to your application's Gemfile:

```ruby
gem "ruby-gemini-ai"
```

And then execute:

```bash
$ bundle install
```

### Gem install

Or install with:

```bash
$ gem install ruby-gemini-ai
```

and require with:

```ruby
require "gemini-ai"
```

## Credentials

- [Option 1: API Key (Generative Language API)](#option-1-api-key-generative-language-api)
- [Option 2: Service Account Credentials File (Vertex AI API)](#option-2-service-account-credentials-file-vertex-ai-api)
- [Option 3: Application Default Credentials (Vertex AI API)](#option-3-application-default-credentials-vertex-ai-api)

#### Option 1: API Key (Generative Language API):

Obtain an API Key from your Google Cloud project: [Google Cloud](https://console.cloud.google.com) through the Google Cloud Console: [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials).

Enable the Generative Language API service in your Google Cloud Console. which can be done [here](https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com).

Alternatively, you can generate an API Key through Google AI Studio [here](https://makersuite.google.com/app/apikey), which will automatically create a project for you.

#### Option 2: Service Account Credentials File (Vertex AI API)

For the Vertex AI API, create a [Google Cloud](https://console.cloud.google.com) Project and a [_Service Account_](https://cloud.google.com/iam/docs/service-account-overview). Enable the [Vertex AI] (https://cloud.google.com/vertex-ai) API for your project [here](https://console.cloud.google.com/apis/library/aiplatform.googleapis.com).

Generate credentials for your Service Account [here](https://console.cloud.google.com/apis/credentials) and download a JSON file named google-credentials.json. 

```json
{
  "type": "service_account",
  "project_id": "YOUR_PROJECT_ID",
  "private_key_id": "a00...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "PROJECT_ID@PROJECT_ID.iam.gserviceaccount.com",
  "client_id": "000...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

Ensure the necessary [policies](https://cloud.google.com/iam/docs/policies) (`roles/aiplatform.user` and possibly `roles/ml.admin`) are in place use the Vertex AI API.

You can add them by navigating to the [IAM Console](https://console.cloud.google.com/iam-admin/iam) and clicking on the _"Edit principal"_ (✏️ pencil icon) next to your _Service Account_.

Alternatively, you can add them through the [gcloud CLI](https://cloud.google.com/sdk/gcloud) as follows:

```sh
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='serviceAccount:PROJECT_ID@PROJECT_ID.iam.gserviceaccount.com' \
  --role='roles/aiplatform.user'
```

Some people reported having trouble accessing the API, and adding the role `roles/ml.admin` fixed it:

```sh
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='serviceAccount:PROJECT_ID@PROJECT_ID.iam.gserviceaccount.com' \
  --role='roles/ml.admin'
```

If you are not using a _Service Account_:
```sh
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='user:YOUR@MAIL.COM' \
  --role='roles/aiplatform.user'

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='user:YOUR@MAIL.COM' \
  --role='roles/ml.admin'
```

#### Option 3: Application Default Credentials (Vertex AI API)


Similar to [Option 2](#option-2-service-account-credentials-file-vertex-ai-api), but you don't need to download a `google-credentials.json`. These automatically find credentials based on your environment. [_Application Default Credentials_](https://cloud.google.com/docs/authentication/application-default-credentials).

Generate them using the gcloud CLI before local development. [gcloud CLI](https://cloud.google.com/sdk/gcloud):

```sh
gcloud auth application-default login 
```

For more details about alternative methods and different environments, check the official documentation:
[Set up Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc)


## Usage 

### Quickstart

For a quick test you can pass your token directly to a new client:

```ruby
client = GeminiAi::Client.new(api_key: "gemini_api_key")
```

### With Config

We can configure Gemini with Ruby using three options.

**Option 1**, API KEY

For a more robust setup, you can configure the gem with your API keys, for example in an `gemini.rb` initializer file. Never hardcode secrets into your codebase - instead use something like [dotenv](https://github.com/motdotla/dotenv) to pass the keys safely into your environments.

```ruby
GeminiAi.configure do |config|
  config.api_key = ENV.fetch("GEMINI_API_KEY")
  config.service = ENV.fetch("GEMINI_API_SERVICE")
end
```

**Option 2**, Service Account

For the Service Account, provide a `google-credentials.json` file and a `REGION`:

```ruby
GeminiAi.configure do |config|
  config.service = 'vertex-ai-api'
  config.region = 'us-east4'
  config.file_path = 'google-credentials.json'
end
```

**Option 3**, Default Credentials

For _Application Default Credentials_, omit both the `api_key` and the `file_path`:

```ruby
GeminiAi.configure do |config|
  config.region = 'us-east4'
  config.service = 'vertex-ai-api'
end
```

Then you can create a client like this:

```ruby
client = GeminiAi::Client.new
```


## Methods

### stream_generate_content(contents, model):

 - Streams generated text in real-time.
 - contents (hash): User input and role information.
 - model (string): Optional model name (e.g., gemini-pro).
 - Returns an array of candidates objects with generated text and safety ratings.

```ruby
client = GeminiAi::Client.new
# Assuming you configured with your API key or credentials

contents = {
  contents: {
    role: 'user',
    parts: {
      text: 'Write a poem about the ocean.'
    }
  }
}

stream = client.stream_generate_content(contents, model: 'gemini-pro')
```

In this case, the result will be an array with all the received events:

```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'text' => 'exmaple poem content.......' }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 2,
     'candidatesTokenCount' => 8,
     'totalTokenCount' => 10
   } }]
```

#### with stream

```ruby
client = GeminiAi::Client.new
# Assuming you configured with your API key or credentials

contents = {
  contents: {
    role: 'user',
    parts: {
      text: 'Write a poem about the ocean.'
    }
  }
}

client.stream_generate_content(contents, model: 'gemini-pro', stream: true) do |part_text, event, parsed, raw|
  puts text
end
```
OR

```ruby
client = GeminiAi::Client.new
# Assuming you configured with your API key or credentials

contents = {
  contents: {
    role: 'user',
    parts: {
      text: 'Write a poem about the ocean.'
    }
  }
}

# Assuming you have a block or procedure (proc) defined
stream_proc = Proc.new do |part_text, event, parsed, raw|
  puts part_text 
end

client.stream_generate_content(contents, model: 'gemini-pro', stream: true, &stream_proc)
```


In this case, the result will be an array with all the received events:

```ruby
'exmaple poem content.......'
```

### generate_content(contents, model)

 - Generates text in a single request.
 - contents (hash): User input and role information.
 - model (string): Optional model name (e.g., gemini-pro).
 - Returns a hash with generated text, safety ratings, and prompt feedback

```ruby
result = client.generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }, model: 'gemini-pro'
)
```

```ruby
client = GeminiAi::Client.new
# Assuming you configured with your API key or credentials

contents = {
  contents: {
    role: 'user',
    parts: {
      text: 'Write a poem about the ocean.'
    }
  }
}

stream = client.generate_content(contents, model: 'gemini-pro')
```


Result:
```ruby
{ 'candidates' =>
  [{ 'content' => { 'parts' => [{ 'text' => 'exampled poem.......' }], 'role' => 'model' },
     'finishReason' => 'STOP',
     'index' => 0,
     'safetyRatings' =>
     [{ 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
  'promptFeedback' =>
  { 'safetyRatings' =>
    [{ 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
     { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
     { 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
     { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] } }
```

#### Verbose Logging

You can pass [Faraday middleware](https://lostisland.github.io/faraday/#/middleware/index) to the client in a block, eg. to enable verbose logging with Ruby's [Logger](https://ruby-doc.org/3.2.2/stdlibs/logger/Logger.html):

```ruby
  client = GeminiAi::Client.new do |f|
    f.response :logger, Logger.new($stdout), bodies: true
  end
```

## Development

 1) Clone the repository.
 2) Run **bin/setup** to install dependencies.
 3) Use **bin/console** for interactive exploration.
 4) Run **bundle exec** rake install to install the gem locally.

## Compatibility

ruby-gemini-ai gem is compatible with Ruby versions 2.6.7 and higher.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Resources and References

Explore the following curated list of resources and references to enhance your understanding throughout the learning process:

- [Google AI for Developers](https://ai.google.dev): Stay updated on the latest developments and resources in the field of Artificial Intelligence by visiting Google AI for Developers.
- [Get started with the Gemini API](https://ai.google.dev/docs): Initiate your journey into the Gemini API with comprehensive guides and documentation provided by Google.
- [Getting Started with the Vertex AI Gemini API with cURL](https://github.com/GoogleCloudPlatform/generative-ai/blob/main/gemini/getting-started/intro_gemini_curl.ipynb): Explore hands-on examples and tutorials using cURL to kickstart your experience with the Vertex AI Gemini API.
- [Gemini API Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini): Refer to the official Gemini API documentation for detailed information on model references and implementation guidelines.
- [Vertex AI API Documentation](https://cloud.google.com/vertex-ai/docs/reference): Dive into the Vertex AI API documentation to gain a comprehensive understanding of Vertex AI services.
- [REST Documentation](https://cloud.google.com/vertex-ai/docs/reference/rest): Explore the RESTful API documentation for Vertex AI to facilitate seamless integration with your applications.
- [Google DeepMind Gemini](https://deepmind.google/technologies/gemini/): Gain insights into Google DeepMind's Gemini technology, a cutting-edge advancement in the field of Artificial Intelligence.
- [Stream responses from Generative AI models](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/streaming): Learn how to effectively stream responses from Generative AI models by consulting this specific guide within the Vertex AI documentation.
- [Function calling](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling): Understand the intricacies of function calling in the context of Generative AI models with this guide from the Vertex AI documentation.

These resources collectively provide a comprehensive foundation for your exploration of the Gemini API and Vertex AI services.

## Additional Notes

- As of now, only generate_content is supported with the `vertex-ai-api` service.
- For detailed API documentation and advanced usage, refer to the official Gemini AI documentation Consider adding examples and error handling for a more user-friendly experience.
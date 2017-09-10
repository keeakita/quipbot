require 'net/http'

require_relative './secrets.rb'

# Wrapper for calls to the Bing Search API
class Bing
  SEARCH_RESULTS = 5
  BING_URL = 'https://api.cognitive.microsoft.com/bing/v5.0/images/search'
  SECRETS = Quipbot::Secrets.secrets['azure']

  def self.image_search(query, count=SEARCH_RESULTS)
    uri = URI(BING_URL)
    uri.query = URI.encode_www_form({
      'q'          => query,
      'count'      => count,
      'offset'     => '0',
      'mkt'        => 'en-us',
      'safeSearch' => 'Moderate'
    })

    request = Net::HTTP::Get.new(uri)
    request['Ocp-Apim-Subscription-Key'] = SECRETS['bing_api']['key']

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    return JSON.parse(response.body)
  end
end


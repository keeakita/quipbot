require 'net/http'

require_relative './secrets.rb'

# Wrapper for requests to the E926 API
class E926
  URL = 'https://e926.net/post/index.json'
  SECRETS = Quipbot::Secrets.secrets['e926']

  def self.fetch_recent_image()
    uri = URI(URL)

    uri.query = URI.encode_www_form({
      'login' => SECRETS['e926_api']['name'],
      'password_hash' => SECRETS['e926_api']['key'],
      'tags' => 'order:random rating:safe score:>20',
      'limit' => '1',
    })

    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'QuipBot [https://github.com/oslerw/quipbot]'

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    url = nil
    if (response.code == '200')
      resp_json = JSON.parse(response.body)
      if resp_json.length != 0
        url = resp_json[0]["file_url"]
      end
    end

    return url
  end
end


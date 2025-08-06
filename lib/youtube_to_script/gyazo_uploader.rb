module YoutubeToScript
  class GyazoUploader
    def initialize(api_token)
      @api_token = api_token
    end
    
    def upload(image_path)
      uri = URI('https://upload.gyazo.com/api/upload')
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_token}"
      
      File.open(image_path, 'rb') do |file|
        request.set_form([['imagedata', file]], 'multipart/form-data')
        
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
        
        if response.code == '200'
          result = JSON.parse(response.body)
          result['url']
        else
          nil
        end
      end
    end
  end
end
module MicrosoftComputerVision
  class Client

    DEFAULT_REGION = :west_us
    REGION_HOST_MAP = {
        west_us: 'westus.api.cognitive.microsoft.com',
        east_us: 'eastus2.api.cognitive.microsoft.com',
        west_central_us: 'westcentralus.api.cognitive.microsoft.com',
        west_europe: 'westeurope.api.cognitive.microsoft.com',
        southeast_asia: 'southeastasia.api.cognitive.microsoft.com'
    }

    def initialize(subscription_key, region = DEFAULT_REGION)
      @subscription_key = subscription_key
      @api_url = "https://#{REGION_HOST_MAP[region]}/vision/v1.0"
    end

    def analyze(image_path, options = {})
      analyze = Api::Analyze.new(@api_url, options[:visual_features], options[:details], options[:language])
      post_image_path(analyze.uri, image_path)
    end

    def describe(image_path, options)
      describe = Api::Describe.new(@api_url, options[:max_candidates])
      post_image_path(describe.uri, image_path)
    end

    def thumbnail(image_path, options)
      thumbnail = Api::Thumbnail.new(options[:width], options[:height], options[:smart_cropping])
      post_image_path(thumbnail.uri, image_path)
    end

    def domain_models
      domain_models = Api::DomainModels.new()
      get(domain_models.uri, {}.to_json)
    end

    def domain_model(image_path, options)
      domain_model = Api::DomainModel.new(options[:model])
      post_image_path(domain_model.uri, image_path)
    end

    def ocr(image_path, options)
      ocr = Api::OCR.new(options[:language], options[:detect_orientation])
      post_image_path(ocr.uri, image_path)
    end

    def tag(image_path)
      tag = Api::Tag.new()
      post_image_path(tag.uri, image_path)
    end

    private

    def post_image_path(uri, image_path)
      image_uri = URI.parse(image_path)

      case image_uri
        when URI::HTTPS, URI::HTTP
          post_image_url(uri, image_path)
        else
          File.open(image_path) do |image_file|
            post_image_data(uri, image_file.read)
          end
      end
    end

    def post_image_data(uri, image_data)
      post(uri, 'application/octet-stream', image_data)
    end

    def post_image_url(uri, image_url)
      post(uri, 'application/json', {url: image_url}.to_json)
    end

    def post(uri, content_type, body)
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = content_type

      start(uri, body, request)
    end

    def get(uri, body)
      request = Net::HTTP::Get.new(uri.request_uri)

      start(uri, body, request)
    end

    def start(uri, body, request)
      request['Ocp-Apim-Subscription-Key'] = @subscription_key
      request.body = body

      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request(request)
      end
    end
  end
end

class HTTPRequester < Requester
  TIMEOUT = 15

  def initialize(invoice_content, **options)
    @invoice_content = StringIO.new(invoice_content)
    @host = URI(VALIDATOR_URL).host
    @manual_redirect = options[:manual_redirect] || false
  end

  def request_validation!
    csrf_token, session_cookies = get_csrf_and_cookie
    headers = {"x-csrf-token" => csrf_token}

    resp = "apparently there was no response"

    if @manual_redirect
      resp = HTTP
        .headers(headers)
        .cookies(session_cookies)
        .post(VALIDATOR_URL, form: {file: HTTP::FormData::File.new(@invoice_content)})

      if [301, 302, 303].include?(resp.code)
        resp = follow_redirect_manually(resp)
      end
    else
      resp = HTTP
        .follow(strict: false)
        .headers(headers)
        .cookies(session_cookies)
        .post(VALIDATOR_URL, form: {file: HTTP::FormData::File.new(@invoice_content)})
    end

    resp
  end

private

  def get_csrf_and_cookie
    response = HTTP.timeout(TIMEOUT).get(VALIDATOR_URL)

    cookie_hash = cookiejar_to_hash(response.cookies)
    doc = Nokogiri::HTML(response.body.to_s)
    csrf_token = doc.css("input")[1].attributes["value"].value

    [csrf_token, cookie_hash]
  end

  def cookiejar_to_hash(jar)
    jar.cookies.each_with_object({}) do |cookie, hash|
      hash[cookie.name] = cookie.value
    end
  end

  def follow_redirect_manually(resp)
    uri = URI(resp.headers["Location"])
    uri.host = @host
    uri.scheme = "http"
    HTTP.get(uri.to_s)
  end
end

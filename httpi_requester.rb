require "http/form_data"

class HTTPIRequester < Requester
  def initialize(invoice_content, **options)
    @invoice_content = StringIO.new(invoice_content)
    @host = URI(VALIDATOR_URL).host

    HTTPI.adapter = options[:backend] || :net_http
  end

  def request_validation!
    csrf_token, session_cookies = get_csrf_and_cookie

    form = HTTP::FormData.create({
      file: HTTP::FormData::File.new(@invoice_content)
    })

    req = HTTPI::Request.new(
      url: VALIDATOR_URL,
      headers: {
        "Cookie" => session_cookies,
        "X-Csrf-Token" => csrf_token,
        "Content-Type" => form.content_type,
      },
      body: form.to_s,
    )

    resp = HTTPI.post(req)

    if [301, 302, 303].include?(resp.code)
      resp = follow_redirect(resp)
    end

    OpenStruct.new({
      status: resp.code,
      body: resp.body,
    })
  end

private

  def get_csrf_and_cookie
    response = HTTPI.get(VALIDATOR_URL)
    cookie = HTTPI::Cookie.new(response.headers["Set-Cookie"])

    doc = Nokogiri::HTML(response.body)
    csrf_token = doc.css("input")[1].attributes["value"].value

    [csrf_token, cookie.name_and_value]
  end

  def follow_redirect(response)
    uri = URI(response.headers["Location"])
    uri.host = @host
    uri.scheme = "http"
    HTTPI.get(uri.to_s)
  end
end

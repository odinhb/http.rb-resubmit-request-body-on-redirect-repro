class FaradayRequester < Requester
  def initialize(invoice_content, **options)
    @invoice_content = invoice_content
    @host = URI(VALIDATOR_URL).host
  end

  def request_validation!
    csrf_token, session_cookies = get_csrf_and_cookie

    conn = Faraday.new do |f|
      f.request :multipart

      f.headers["Cookie"] = session_cookies
      f.headers["X-Csrf-Token"] = csrf_token
    end

    payload = {
      file: Faraday::FilePart.new(
        StringIO.new(@invoice_content),
        "application/octet-stream",
        "invoice.xml",
      )
    }

    resp = conn.post(VALIDATOR_URL, payload)

    if [301, 302, 303].include?(resp.status)
      resp = follow_redirect(resp)
    end

    resp
  end

private

  def get_csrf_and_cookie
    resp = Faraday.get(VALIDATOR_URL)
    cookie_header = resp.headers["Set-Cookie"]

    doc = Nokogiri::HTML(resp.body)
    csrf_token = doc.css("input")[1].attributes["value"].value

    [csrf_token, cookie_header]
  end

  def follow_redirect(response)
    uri = URI(response.headers["location"])
    uri.host = @host
    Faraday.get(uri.to_s)
  end
end

class SocketRequester < Requester
  BOUNDARY = "---------------------543313411d7992fd73f077adace725c901582640ff"

  def initialize(invoice_content, **options)
    @invoice_content = invoice_content
    @uri = URI(VALIDATOR_URL)
    @host = @uri.host
    @port = @uri.port
    @user_agent = "RAW SOCKET WRITER"
  end

  def request_validation!
    # puts
    # puts "SocketRequester: Host: #{@host.inspect}, port: #{@port.inspect}"

    csrf_token, cookies = get_csrf_and_cookie

    resp = post_content(csrf_token, cookies)
    status = extract_status(resp)

    if status == 302 || status == 301 || status == 303
      headers, body = follow_redirect(resp)
      status = extract_status(headers)
    end

    OpenStruct.new(status: status, body: body)
  end

private

  def get(path)
    socket = TCPSocket.new(@host, @port)
    # puts "opened socket: #{socket.inspect}"

    # puts "GETTING #{path}"
    req = "GET #{path} HTTP/1.1\r\n"
    req += "Host: #{@host}:#{@port}\r\n"
    req += "User-Agent: #{@user_agent}\r\n"
    req += "Connection: close\r\n"
    req += "\r\n"
    socket.write req

    resp = socket.read
    # puts "GOT #{path}: #{resp.lines.first}"

    headers, body = resp.split("\r\n\r\n")

    # puts
    # puts "RESP HEAD:"
    # puts headers

    [headers, body]
  ensure
    socket.close
  end

  def extract_status(headers)
    # puts "EXTRACT status: HEADERS: #{headers.inspect}"
    mdat = headers.lines.first.match(/HTTP\/\d\.\d (\d\d\d)/)

    # puts "mdat: #{mdat.inspect}"

    status = mdat&.[](1)&.to_i
  end

  def get_csrf_and_cookie
    headers, body = get(@uri.path)
    # puts "RESP BODY:"
    # puts body
    # puts

    cookies = headers.match(/^Set-Cookie: (.*)/)[1]
    cookies.sub!("Path=/; HttpOnly", "")
    # puts "COOKIES: #{cookies}"

    doc = Nokogiri::HTML(body)
    csrf_token = doc.css("input")[1].attributes["value"].value

    # puts "csrf_token: #{csrf_token}"

    [csrf_token, cookies]
  end

  def post_content(csrf_token, cookie)
    socket = TCPSocket.new(@host, @port)

    post_body, content_length = build_post_body(@invoice_content)

    req = "POST / HTTP/1.1\r\n"
    req += "Host: #{@host}:#{@port}\r\n"
    req += "User-Agent: #{@user_agent}\r\n"
    req += "X-Csrf-Token: #{csrf_token}\r\n"
    req += "Cookie: #{cookie}\r\n"
    req += "Connection: close\r\n"
    req += "Content-Length: #{content_length}\r\n"
    req += "Content-Type: multipart/form-data; boundary=#{BOUNDARY}\r\n"
    req += "\r\n"
    req += post_body
    # puts "POSTING (content_length: #{content_length})..."
    socket.write req
    # written = 0
    # until written >= content_length
    #   write_result = socket.write_nonblock(req, exception: false)
    #   if write_result == :wait_writable
    #     puts "got told to wait..."
    #     sleep 0.1
    #   else
    #     written += write_result
    #     puts "wrote #{write_result}b, total written: #{written}b/#{content_length}b"
    #   end
    # end

    # puts "POSTED, waiting for response..."

    resp = socket.read

    headers, body = resp.split("\r\n\r\n")

    # puts
    # puts "RESP HEAD:"
    # puts headers
    if body
      # puts "RESP BODY:"
      # puts body
      # puts "RESP BODY SIZE: #{body.size}"
      # puts
    end
    # puts "RESP BODY:"
    # puts body

    resp
  ensure
    socket.close
  end

  def build_post_body(content)
    bod = "--#{BOUNDARY}\r\n"
    # TODO: add subheaders here
    # bod += "Content-Disposition: form-data; name=\"da file\"\r\n"
    bod += "Content-Disposition: form-data; name=\"file\"; filename=\"stream-47328861772060\"\r\n"
    bod += "Content-Type: application/octet-stream\r\n"
    bod += "\r\n"
    bod += @invoice_content
    bod += "\r\n"
    bod += "--#{BOUNDARY}--\r\n"
    # bod += "\r\n"

    [bod, bod.bytesize]
  end

  def follow_redirect(stuff)
    headers, body = stuff.split("\r\n\r\n")

    address = headers.lines.find { |l| l.start_with?("Location") }
    address = address.split(": ").last
    address = address&.chomp

    uri = URI(address)
    get(uri.path)
  end
end

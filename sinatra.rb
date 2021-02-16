require "bundler/inline"

puts "loading gems..."
gemfile do
  source "https://rubygems.org"

  gem "sinatra"
end
puts "gems loaded"

class BodyLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    headers = env
      .filter { |key, _| key.start_with?("HTTP_") }
      .map { |h, v| [h.sub("HTTP_", ""), v] }

    puts "HEADERS FOR #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}:"
    headers.each do |header, value|
      puts "#{header}: #{value.inspect}"
    end
    puts "CoNtEnT-TyPE: #{env["CONTENT_TYPE"].inspect}" if env["CONTENT_TYPE"]
    puts "CoNtEnT-leNGtH: #{env["CONTENT_LENGTH"].inspect}" if env["CONTENT_LENGTH"]

    req = Rack::Request.new(env)
    req.body.rewind
    body_extracted = req.body.read
    req.body.rewind
    puts "BODY (ACTUAL LENGTH: #{body_extracted.bytesize}) (first 500 bytes):"
    puts body_extracted.byteslice(0, 500)
    puts
    @app.call(env)
  end
end

use BodyLogger

get "/" do
  headers("Set-Cookie" => "cookie1=test;")
  body <<~HTML
    <html>
      <body>
        <input name="da_invoice_u_validating">
        <input type="hidden" name="_csrf" value="abcd_csrf">
      </body>
    </html>
  HTML
end

def cookie_correct?
  cookie = request.env["HTTP_COOKIE"]
  return true if cookie.match?(/cookie1=test/)

  false
end

def csrf_correct?
  token = request.env["HTTP_X_CSRF_TOKEN"]
  return true if token == "abcd_csrf"

  false
end

post "/" do
  if cookie_correct? && csrf_correct?
    redirect to("/redirectmehere"), 302
  else
    status 403
    body "cookie_correct?: #{cookie_correct?}\ncsrf_correct?: #{csrf_correct?}"
  end
end

get "/redirectmehere" do
  puts "REQUEST BODY SIZE IN REDIRECT REQUEST: #{request.body.size} (SHOULD BE 0)"
  puts

  if request.body.size == 0
    status 200
    body "WIN :D"
  else
    status 400
    body "FAIL D:"
  end
end

require_relative "./gemfile"

class Integer
  def kilobytes
    self * 1024
  end

  def megabytes
    self.kilobytes * 1024
  end
end

class Requester
  def self.go!(invoice, **kwopts)
    new(invoice, **kwopts).request_validation!
  end
end

require_relative "./cause_chain"

require_relative "./http_requester"
HTTPI.log = false # this wrapper is kinda noisy by default
require_relative "./httpi_requester"
require_relative "./faraday_requester"
require_relative "./socket_requester"

$failures = {}

def test!(requester, **kwopts)
  puts "TESTING: #{requester} w/ #{kwopts}"

  TEST_RUNS.times do |n|
    print "TEST #{n}: "

    resp = requester.go!(TEST_CONTENT, **kwopts)

    if resp
      print "STATUS RECEIVED: #{resp.status} "
      if resp.status != 200
        raise "http status was not 200"
      end

      if resp.body.to_s.size == 0
        raise "response body was empty"
      end
    else
      raise "response was nil"
    end

  rescue StandardError => e
    $failures[requester] ||= 0
    $failures[requester] += 1
    print "❌ FAIL: "

    puts "error raised: #{e.class}: #{e.message}"
    puts "STACK: #{e.backtrace.join("\n")}"

    unwind_causes(e)

    puts
  else
    print "✓ SUCCESS\n\n"
  end
end

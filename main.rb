require_relative "./setup"

VALIDATOR_URL = "http://localhost:4567/" # sinatra app
# VALIDATOR_URL = "http://vefa.fakturabank.no/"

BIN_DAT_CHAR_CYCLE = "thiswouldbeanxml".split("").cycle
TEST_RUNS = 1
# threshold for failure seems to be ~3 megabytes
# TEST_FILE_SIZE = 120.megabytes
# TEST_FILE_SIZE = 7.megabytes
TEST_FILE_SIZE = 100
TEST_CONTENT = BIN_DAT_CHAR_CYCLE.take(TEST_FILE_SIZE).join

puts "testing against #{VALIDATOR_URL} with a string of size #{TEST_CONTENT.size} bytes"

# irrelevant experiments
# test!(SocketRequester)
# test!(FaradayRequester)

# this one crashes intermittently with big request bodies
test!(HTTPRequester, manual_redirect: false)
test!(HTTPRequester, manual_redirect: true)
test!(HTTPIRequester, backend: :net_http)
test!(HTTPIRequester, backend: :http)

puts "FAILURES:"
$failures.each do |klass, fails|
  puts "#{klass}: #{fails} failures"
end

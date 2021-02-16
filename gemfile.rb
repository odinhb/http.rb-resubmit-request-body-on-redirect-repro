require "bundler/inline"

puts "ruby ver: #{RUBY_VERSION}"
puts "loading gems..."

gemfile do
  source "https://rubygems.org"

  gem "http"
  gem "faraday"
  gem "httpi"

  gem "byebug"

  gem "nokogiri" # im sorry
end

puts "gems loaded"
puts

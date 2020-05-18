# NOTE: These are development-only dependencies
source "https://rubygems.org"

# Specify your gem's dependencies in shopify-cli.gemspec
gemspec

# None of these can actually be used in a development copy of dev
# They are all for CI and tests
# `dev` uses no gems
group :development, :test do
  gem 'rake', '~> 12.3', '>= 12.3.3'
  gem 'pry-byebug'
  gem 'byebug'
  gem 'rubocop'
end

group :test do
  gem 'session'
  gem 'mocha', require: false
  gem 'minitest', '>= 5.0.0', require: false
  gem 'minitest-reporters', require: false
  gem 'fakefs', require: false
  gem 'webmock', require: false
end

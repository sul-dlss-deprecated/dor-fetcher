require 'bundler/setup'
Bundler.setup
require 'dor-fetcher'
require 'json'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end


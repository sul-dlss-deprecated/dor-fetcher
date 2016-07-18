require 'dor-fetcher'
require 'json'
require 'vcr'
require 'coveralls'
Coveralls.wear!

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

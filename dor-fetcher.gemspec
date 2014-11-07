Gem::Specification.new do |s|
  s.name        = 'dor-fetcher'
  s.version     = '1.0.4'
  s.date        = '2014-11-07'
  s.summary     = "DorFetcher Gem"
  s.description = "Wrapper for the Dor Fetcher Services RESTful API."
  s.authors     = ["Carrick Rogers", "Laney McGlohon", "Bess Sadler"]
  s.email       = ['carrickr@stanford.edu', 'laneymcg@stanford.edu', 'bess@stanford.edu']
  s.files       = Dir.glob("lib/**/*")
  s.homepage    = "http://www.stanford.edu"
  s.license     = "Apache-2.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "vcr"
  s.add_development_dependency "webmock"
  s.add_development_dependency "yard"
  s.add_development_dependency "coveralls"
end

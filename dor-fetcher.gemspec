Gem::Specification.new do |s|
  s.name        = 'dor-fetcher'
  s.version     = '0.0.3'
  s.date        = '2014-10-20'
  s.summary     = "DorFetcher Gem"
  s.description = "Wrapped for the Dor Fetcher Services restful api."
  s.authors     = ["Carrick Rogers", "Laney McGlohon"]
  s.email       = ['carrickr@stanford.edu', 'laneymcg@stanford.edu']
  s.files       = Dir.glob("lib/**/*") + Dir.glob("config/**/*") + Dir.glob('bin/*')
  s.homepage    = "http://www.stanford.edu"
  s.license     = "Apache-2.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "vcr"
  s.add_development_dependency "webmock"
  s.add_development_dependency "yard"
  s.add_development_dependency "coveralls"
end

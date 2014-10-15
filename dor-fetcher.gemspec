Gem::Specification.new do |s|
  s.name        = 'dor-fetcher'
  s.version     = '0.0.2'
  s.date        = '2014-10-10'
  s.summary     = "DorFetcher Gem"
  s.description = "Wrapped for the Dor Fetcher Services restful api."
  s.authors     = ["Carrick Rogers"]
  s.email       = 'carrickr@stanford.edu'
  s.files       = Dir.glob("lib/**/*") + Dir.glob("config/**/*") + Dir.glob('bin/*')
  s.homepage    = "http://www.stanford.edu"
  s.add_development_dependency "rspec"
end
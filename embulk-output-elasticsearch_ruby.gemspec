
Gem::Specification.new do |spec|
  spec.name          = "embulk-output-elasticsearch_ruby"
  spec.version       = "0.1.4"
  spec.authors       = ["toyama0919"]
  spec.summary       = "Elasticsearch Ruby output plugin for Embulk. Elasticsearch 1.X AND 2.X AND 5.X compatible."
  spec.description   = "Dumps records to Elasticsearch Ruby. Elasticsearch 1.X AND 2.X AND 5.X compatible."
  spec.email         = ["toyama0919@gmail.com"]
  spec.licenses      = ["MIT"]
  spec.homepage      = "https://github.com/toyama0919/embulk-output-elasticsearch_ruby"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'elasticsearch'
  spec.add_dependency 'excon'
  spec.add_development_dependency 'bundler', ['~> 1.0']
  spec.add_development_dependency 'embulk', ['>= 0.8.16']
  spec.add_development_dependency 'rake', ['>= 10.0']
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'test-unit-rr'
end

# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "github-ldap"
  spec.version       = "1.10.1"
  spec.authors       = ["David Calavera", "Matt Todd"]
  spec.email         = ["david.calavera@gmail.com", "chiology@gmail.com"]
  spec.description   = %q{LDAP authentication for humans}
  spec.summary       = %q{LDAP client authentication wrapper without all the boilerplate}
  spec.homepage      = "https://github.com/github/github-ldap"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'net-ldap', '~> 0.16.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'ladle'
  spec.add_development_dependency 'minitest', '~> 5'
  spec.add_development_dependency "rake"
end

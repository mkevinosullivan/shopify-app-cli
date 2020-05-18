require_relative 'lib/shopify-cli/version'

Gem::Specification.new do |spec|
  spec.name          = "shopify-cli"
  spec.version       = ShopifyCli::VERSION
  spec.authors       = ["Shopify"]
  spec.email         = ["development@shopify.com"]
  spec.license       = 'Nonstandard'

  spec.summary       = %q{Shopify App CLI helps you build Shopify apps faster.}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://shopify.github.io/shopify-app-cli/"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Shopify/shopify-app-cli"
  spec.metadata["changelog_uri"] = "https://github.com/Shopify/shopify-app-cli/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # The `cat ls-files`.split("\n") loads files specified in a file called ls-files (for testing)
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib", "vendor"]

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency 'minitest', '~> 5.0'
end

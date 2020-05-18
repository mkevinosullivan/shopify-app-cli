require_relative 'lib/shopify_cli/version'

Gem::Specification.new do |spec|
  spec.name          = "shopify-app-cli"
  spec.version       = ShopifyCli::VERSION
  spec.authors       = ["Kevin O'Sullivan"]
  spec.email         = ["mkevin.osullivan@shopify.com"]
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
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `cat ls-files`.split("\n")
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_runtime_dependency 'cli-kit', '~> 3.3'
  spec.add_runtime_dependency 'cli-ui', '~> 1.3'
  spec.add_runtime_dependency 'smart_properties', '=1.14'
  spec.add_runtime_dependency 'semantic', '~> 1.6'
end

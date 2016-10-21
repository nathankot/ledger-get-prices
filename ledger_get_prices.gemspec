# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ledger_get_prices/version'

Gem::Specification.new do |spec|
  spec.name          = "ledger_get_prices"
  spec.version       = LedgerGetPrices::VERSION
  spec.authors       = ["Nathan Kot"]
  spec.email         = ["nk@nathankot.com"]
  spec.summary       = 'Intelligently update your ledger pricedb'
  spec.homepage      = 'https://github.com/nathankot/ledger-get-prices'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "yahoo-finance", "~> 1.1.0"
end

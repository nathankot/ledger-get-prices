Gem::Specification.new do |s|
  s.name = 'ledger-get-prices'
  s.version = '0.0.3'
  s.authors = ['Nathan Kot']
  s.email = 'nk@nathankot.com'
  s.files = `git ls-files`.split($\)
  s.executables = ["getprices"]
  s.require_paths = ["lib"]
  s.license = 'MIT'
  s.has_rdoc = 'yard'

  s.homepage = 'https://github.com/nathankot/ledger-get-prices'
  s.summary = 'Intelligently update your ledger pricedb'
  s.description = <<-eof
    A tool that updates your ledger's pricedb based on
    the commodities you have used, and the best start/end
    dates based on your journal.

    It uses the gem `yahoo-finance` internally to get quotes.
  eof
end

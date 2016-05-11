require "ledger_get_prices/version"
require 'date'
require 'open-uri'
require 'yahoo-finance'

module LedgerGetPrices

  # = Synopsis
  #
  # Tool that uses Yahoo finance to intelligently generate
  # a ledger price database based on your current ledger
  # commodities and time period.
  #
  # Ensure that you have set the +LEDGER+ and +LEDGER_PRICE_DB+
  # environment variables before proceeding. Alternatively, you
  # can make the same addition to your +.ledgerrc+, so long as
  # running +ledger+ vanilla knows where to get the journal and
  # pricedb.
  #
  # = Options
  #
  # +LEDGER_BASE_CURRENCY+: Defaults to USD, change this to your reporting currency.
  # +LEDGER_PRICE_DATE_FORMAT+: The date format of the outputted pricedb. Defaults to +%Y/%m/%d+.
  class GetPrices
    class << self

      # Yahoo finance works best in USD, if the base currency is
      # different we will also store the USD price of that currency
      # to allow for conversion.
      BASE_CURRENCY = ENV['LEDGER_BASE_CURRENCY'] || "USD"

      PRICE_DB_PATH = ENV['LEDGER_PRICE_DB'] || ENV['PRICE_HIST'] # PRICE_HIST is <v3
      DATE_FORMAT = ENV['LEDGER_PRICE_DATE_FORMAT'] || "%Y/%m/%d"
      PRICE_FORMAT = "P %{date} %{time} %{symbol} %{price}"
      COMMODITY_BLACKLIST = (ENV['LEDGER_PRICE_COMMODITY_BLACKLIST'] || '').split(" ")

      # With a bang because it does a file write.
      def run!
        File.write(PRICE_DB_PATH, new_prices.join("\n"))
      end

      # We work with the database as an array of price definitions
      # @return [Array] an array of formatted prices
      def existing_prices
        @existing_prices ||= File.read(PRICE_DB_PATH)
                                .split("\n")
                                .reject { |x| (/^P.*$/ =~ x) != 0 }
      end

      # This method builds a new price database intelligently.
      #
      # @return [Array] an array of formatted prices
      def new_prices
        commodities.reduce(existing_prices) do |db, c|
          # `|` is a shortcut for merge
          db | prices_for_symbol(c, start_date: start_date, end_date: end_date)
              .map { |x| price_string_from_result(x, symbol: c) }
        end
      end

      # @return [Array] of YahooFinance results (OpenStruct)
      def prices_for_symbol(symbol, start_date: start_date, end_date: end_date) # -> Array
        puts "Getting historical quotes for: #{symbol}"

        if COMMODITY_BLACKLIST.include?(symbol)
          puts "Skipping #{symbol}: blacklisted."
          puts "Use `LEDGER_PRICE_COMMODITY_BLACKLIST` to configure the blacklist."
          return []
        end

        result = nil
        quote_strings = possible_quote_strings(commodity: symbol)
        err = nil

        while quote_strings.length > 0 && result.nil?
          begin
            result = YahooFinance::Client.new.historical_quotes(
              quote_strings.shift, start_date: start_date, end_date: end_date, period: :daily)
          rescue OpenURI::HTTPError => e
            err = e
          end
        end

        if result.nil?
          puts "Could not get quotes from Yahoo for: #{symbol}"
          puts "It may be worthwhile getting prices for this manually."
          []
        else result
        end
      end

      # @return [String]
      def price_string_from_result(data, symbol: nil)
        raise "Must pass symbol" if symbol.nil?
        PRICE_FORMAT % {
          date: Date.strptime(data.trade_date, '%Y-%m-%d').strftime(DATE_FORMAT),
          time: '23:59:59',
          symbol: (BASE_CURRENCY == 'USD' ? '$' : 'USD'),
          price: (BASE_CURRENCY == symbol ? '$' : symbol)+ data.close
        }
      end

      protected

      # Start date is either the latest price record or the earliest
      # ever transaction.
      # @return [Date]
      def start_date
        @start_date ||= existing_prices.map { |x| Date.strptime(x.split(" ")[1], DATE_FORMAT) }.max || begin
          stats = `ledger stats` # Most compact way to retrieve this data
          date_str = /Time\speriod:\s*([\d\w\-]*)\s*to/.match(stats)[1]
          return Date.strptime(date_str, "%y-%b-%d")
        end
      end

      # End date is today, wish I can see the future but unfortunately..
      # @return [Date]
      def end_date
        @end_date ||= Date.new()
      end

      # Try the commodity as a currency first, before trying it as a stock
      # @return [Array<String>] Possible Yahoo finance compatible quote strings
      def possible_quote_strings(commodity: nil)
        raise "No commodity given" if commodity.nil?
        ["#{commodity}=X", "USD#{commodity}=X", "#{commodity}"]
      end

      def commodities
        # All the commodities we care about.
        @commodities ||= `ledger commodities`.split("\n").reject { |x| x == "$" }.tap do |c|
          c << BASE_CURRENCY if BASE_CURRENCY != 'USD'
        end
      end

    end
  end

end

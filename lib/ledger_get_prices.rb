require "ledger_get_prices/version"
require 'date'
require 'open-uri'
require 'net/http'
require 'json'

module LedgerGetPrices

  # = Synopsis
  #
  # Tool that uses Bloomberg to intelligently generate
  # a ledger price database based on your current ledger
  # commodities and time period.
  #
  # Ensure that you have set the +LEDGER+ and +LEDGER_PRICE_DB+
  # environment variables before proceeding. Alternatively, you
  # can make the same addition to your +.ledgerrc+, so long as
  # running +ledger+ vanilla knows where to get the journal and
  # pricedb.
  #
  # All quotes are fetched relative to USD.
  #
  # = Options
  #
  # +LEDGER_PRICE_DATE_FORMAT+: The date format of the outputted pricedb. Defaults to +%Y/%m/%d+.
  class GetPrices
    class << self

      # The base currency should be the currency that the dollar sign represents in your reports.
      BASE_CURRENCY = ENV['LEDGER_BASE_CURRENCY'] || "USD"

      PRICE_DB_PATH = ENV['LEDGER_PRICE_DB'] || ENV['PRICE_HIST'] # PRICE_HIST is <v3
      DATE_FORMAT = ENV['LEDGER_PRICE_DATE_FORMAT'] || "%Y/%m/%d"
      PRICE_FORMAT = ENV['LEDGER_PRICE_FORMAT'] || "P %{date} %{time} %{symbol} %{price}"
      COMMODITY_BLACKLIST = (ENV['LEDGER_PRICE_COMMODITY_BLACKLIST'] || 'BTC ETH').split(" ")

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
        # Since everything is relative to USD, we don't need to fetch it.
        commodities
          .reject { |c| c == "USD" }
          .reduce(existing_prices) do |db, c|
            # `|` is a shortcut for merge
            db | prices_for_symbol(c, start_date: start_date)
                .map { |x| price_string_from_result(x, symbol: c) }
          end
      end

      # @return [Array] of results (OpenStruct)
      def prices_for_symbol(symbol, start_date: nil) # -> Array
        puts "Getting historical quotes for: #{symbol}"

        if COMMODITY_BLACKLIST.include?(symbol)
          puts "Skipping #{symbol}: blacklisted."
          puts "Use `LEDGER_PRICE_COMMODITY_BLACKLIST` to configure the blacklist."
          puts "BTC is blacklisted by default because Bloomberg doesn't support it."
          return []
        end

        err = nil

        query = "#{symbol}USD:CUR"
        uri = URI.parse("https://www.bloomberg.com/markets/api/bulk-time-series/price/#{query}?timeFrame=1_YEAR")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)
        req.initialize_http_header({
          'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36',
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
          'Accept-Language' => 'en-US,en;q=0.9',
          'Cookie' => '',
        })
        response = http.request(req)
        response_json = JSON.parse response.body

        unless response_json.kind_of?(Array)
          puts "Could not parse response from Bloomberg: #{response_json}"
          return []
        end

        response_json = response_json[0]

        unless response_json != nil and response_json["price"] != nil and response_json["price"].respond_to? :map then
          puts "Could not get quotes for: #{symbol}"
          puts "It may be worthwhile getting prices for this manually."
          return []
        end

        return response_json["price"]
          .map { |data|
            date = Date.strptime(data["date"])
            time = Time.new(date.year, date.month, date.day, 23, 59, 59)
            value = data["value"]
            result = {
              :time => time,
              :symbol => symbol,
              :price => "USD#{value}"
            }
            result
          }
          .select { |data| data[:time].to_date >= start_date }
      end

      # @return [String]
      def price_string_from_result(data, symbol: nil)
        raise "Must pass symbol" if symbol.nil?
        PRICE_FORMAT % {
          date: data[:time].to_date.strftime(DATE_FORMAT),
          time: data[:time].strftime("%H:%M:%S"),
          symbol: data[:symbol],
          price: data[:price]
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

      def commodities
        # All the commodities we care about.
        @commodities ||= `ledger commodities`.split("\n")
          .reject { |x| x == "$" }
          .tap { |c| c << BASE_CURRENCY }
          .uniq
      end

    end
  end

end

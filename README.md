## ledger-get-prices

It's the end of financial year, and now that I'm accounting with NZD,USD,JPY,BTC I've spent some time to automate the
pricedb process. Enjoy :) PR's welcome.

# Synopsis

_Tool that uses Bloomberg to intelligently generate
a ledger price database based on your current ledger
commodities and time period._

Ensure that you have set the `LEDGER` and `LEDGER_PRICE_DB`
environment variables before proceeding. Alternatively, you
can make the same addition to your `.ledgerrc`, so long as
running `ledger` vanilla knows where to get the journal and
pricedb.

# Environment Variables

* __LEDGER_BASE_CURRENCY__: Defaults to USD, change this to your reporting currency.
* __LEDGER_PRICE_DATE_FORMAT__: The date format of the outputted pricedb. Defaults to `%Y/%m/%d`.

# Usage

```sh
gem install ledger_get_prices
getprices # This will WRITE to your LEDGER_PRICE_DB file.
```

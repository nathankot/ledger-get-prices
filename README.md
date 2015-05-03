## ledger-get-prices

It's the end of financial year, and now that I'm accounting with NZD,USD,JPY,BTC I've spent some time to automate the
pricedb process. Enjoy :) PR's welcome.

# Synopsis

_Tool that uses Yahoo finance to intelligently generate
a ledger price database based on your current ledger
commodities and time period._

Ensure that you have set the `LEDGER` and `LEDGER_PRICE_DB`
environment variables before proceeding. Alternatively, you
can make the same addition to your `.ledgerrc`, so long as
running `ledger` vanilla knows where to get the journal and
pricedb.

# Environment Variables

* __LEDGER_BASE_CURRENCY__: Defaults to USD, change this to your reporting currency.
* __LEDGER_PRICE_DATE_FORMAT__: The date format of the outputted pricedb. Defaults to +%Y/%m/%d+.

# License

The MIT License (MIT)

Copyright (c) 2015 Nathan Kot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

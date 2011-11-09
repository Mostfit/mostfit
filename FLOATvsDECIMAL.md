FLOAT vs DECIMAL
================

This is a small write-up on the issue of using Float vs Decimal for
representing monetary data in financial software.

When I started to work on Mostfit in Jan'09 I used integers for monetary
data.  In india we could store rupees, in other countries we could
simply store 'cents' and then add the decimal point with a helper in the
views.

Later we move to using 'floats'... It is often said that floats are no
adequat for monetary data as they are inacurate.  Example:

     1.2 - 1.0 == 0.2  # => false, in most languages

When we apply rounding OVER EACH OPERATION we can largely fix this
problem but it is not nice.

There are numerous sources claiming float for monerary data are evil,
here are some link to that:

http://stackoverflow.com/questions/61872/use-float-or-decimal-for-accounting-application-dollar-amount

http://stackoverflow.com/questions/1019939/ruby-on-rails-best-method-of-handling-currency-money

https://lists.launchpad.net/openerp-expert-accounting/msg00070.html

The last link is from a Tryton dev who forked OpenERP.  The next link is
from the founder of OpenERP on the merits of floats for financial data:

https://lists.launchpad.net/openerp-expert-accounting/msg00067.html

Besides OpenERP also Lazy8Ledger uses floats.  That said most others use
singed integers (possibly wrapped in some sort of 'decimal' class for
carrying the decimal point).


## Rounding

A slightly relating issue is rounding.  Mathmatically we round 'halfs'
as shown in the following pseudo code:

     round(1.5) == 2 and round(0.4) == 0

But in financial software we often find a rounding method know as [half
to even](http://en.wikipedia.org/wiki/Rounding#Round_half_to_even)
(alternatively known as Dutch, statistical or financial rounding).

In Ruby the BigDecimal class facilitates this kind of rounding, the
Float class does not.



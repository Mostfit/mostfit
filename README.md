Mostfit: the open source MIS for MFIs
=====================================

Mostfit (see also our [offical website](http://mostfit.org)) is an [MIS](http://en.wikipedia.org/wiki/Management_information_systems) for Micro Finance Institutes (MFIs).

It has originally been created by [Intellecap](http://intellecap.com/)'s Technology Solutions Group which has since 2011 been made into a company of its own called [ISTPL](http://istpl.in).  ISTPL is fully committed to future development, maintenance and hosting of Mostfit.

The software is web-based, fully [open source](http://en.wikipedia.org/wiki/Open_source) and is used by an ever growing number of micro credit lenders to facillitate their day-to-day operations.  Open source software ensures certain freedoms to those who depend on it; roughly this translates to:

  * the freedom to use it for any purpose (at zero cost)
  * the freedom to make modifications
  * the freedom to copy (with or without modifications)

The only "but" is that the license ([AGPLv3](http://www.gnu.org/licenses/agpl.html)) of our software is not changed or remove, thereby ensuring these freedoms are available to anyone who obtains a copy.  For more information about the freedoms of open source see the [website of the GNU organization](http://www.gnu.org/philosophy/free-sw.html), who have create the license that we use to release Mostfit.

We have chosen to release our software as open source to give our clients more freedom and therefor more confidence.  It is basically a promise to our customers that we will deliver our services at a competitive price point, without ever abusing their dependency on our product.

For more information have a look at the official website, [mostfit.org](http://mostfit.org), or [try our online demo](http://demo.mostfit.in)!


## Technical notes

This software is written in the [Ruby](http://ruby-lang.org) programming language (which is available as open source).  We make use of many so-called libraries (all of which are open source), of which the biggest ones are:

  * the [Merb](http://merb.org) web framework (currently assimilated into [Rails](http://rubyonrails.org) 3)
  * the [DataMapper](http://datamapper.org) [ORM](http://en.wikipedia.org/wiki/Object-relational_mapping)
  * the [RSpec](http://relishapp.com/rspec) testing toolkit

Mostfit runs on any modern open source platform.  We perfer the [Ubuntu Linux](http://ubuntu.com) distribution, the [Apache](http://httpd.apache.org) webserver with [Phusion Passenger](http://www.modrails.com) and a [MySQL](http://www.mysql.com) database.


## Installation

See the `INSTALL.md` file first.

After installation you could then run:

    rake mock:load_demo

Go get a cup of coffee when you see text whizzing by and by the time you finish your delicious beverage, the demo fixtures should have been loaded and the system set up for your use.  Finally run `bin/merb` to start the server.

More detailed instructions are available [in our wiki](https://github.com/Mostfit/mostfit/wiki/How-to-install).


## Customizing

Any proper Ruby programmer, or software shop, should be able to help you out customizing Mostifit to your needs.

We use [git](http://git-scm.com) and [Github](http://github.com), that means you can easily maintain own version of our software and keep it in sync with future changes.  That is good for the following reasons:

 * keep up with fixes and enhancements
 * easily contribute your changes back to the community
 * incorporate community innovation

Which brings us to our goals of sharing costs, being flexible and delivering the best --free for all-- though open innovation.


## License

Copyright (c) 2009-2012 Intellecap/ISTPL.

Mostfit is available under the GNU AFFERO GENERAL PUBLIC LICENSE version 3 or (at your option) any later version. You should have received a file named `LICENSE.AGPLv3` along with Mostfit, this contains the complete text of the license.



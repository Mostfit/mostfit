h1. MISFIT:  an MIS for MFIs.

This software is build using the Ruby programming language, on top of the Merb web framework and the DataMapper ORM. MISFIT takes a minimal approach, it basically creates the application in the most generic form, yet fully usable for the needs of our clients and beyond. You can see our demo at http://mostfit.intellecap.in

h2. Philosophy

A dead-simple, easy-to-use and easy-to-adapt, webbased MIS for MFIs with a decent feature set.

Many software has been written to accomplish this. Not much was written well. Most of it is closed source, so suffers from limited exposure and often stalled development. We try to do is right by creating just enough.

h2. Installation

Edit config/dependencies.rb and make sure you have the correct version of the gems required. Edit config/example.database.yml, update the db name, username and password to reflect your database settings and save it as config/database.yml. Then:
rake mock:load_demo
Go get a cup of coffee when you see text whizzing by and by the time you finish your delicious beverage, the demo fixtures should have been loaded and the system set up for your use.
Run "bin/merb" to start the server

h2. Customizing

Customizing MISFIT is very simple, in most cases not many modifications will be needed in order to fit your needs. In case you want to create different types of loan (different payment schemes and other acocunting details) just subclass from the Loan class in /app/models/loan.rb. There should be already some specific loan types there. For other modifications, like disabeling some functionality or adding a field, we suggest you just modify the code directly.

Any proper Ruby programmer, or software shop, should be able to help you out customizing this tool to their needs.

We use github, that means you can easily host your own branch of this software. That is good for the following reasons:
 * keep up with our updates
 * easily contribute your changes back to the community
 * incorporate community innovation

Which brings us to our goals of sharing costs, being flexible and delivering the best --free for all-- though open innovation. The license is AGPLv3, which is considered a strong-copyleft (viral) Open and Free Software license.

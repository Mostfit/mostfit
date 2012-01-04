INSTALLING
==========

This document describes how to quickly install Mostfit (the branch that you are looking at).

Both `rvm` and `gemsets` are employed to do so.

This is not a copy-paste script for a clean install ubuntu -- YMMV.



##  SECOND ATTEMPT

I heard that I was doing it wrong, so here my second attempt.  This seems to work nicely.


    git clone git@git.mostfit.in:mostfit.git
    git co new-layout

    rvm use 1.8.7  # install it if you haven't got it already
    rvm gemset create mostfit-new-layout
    rvm 1.8.7@mostfit-new-layout
    rvm rubygems 1.4.2

    (cd gems/cache; gem install --local * --no-ri --no-rdoc)
    # got errors: pdf-writer wants color, and roo wants spreadsheet, google-spreadsheet-ruby wants hpricot

    cp config/example.database.yml config/database.yml
    vi config/database.yml

    bin/merb





##  FIRST ATTEMPT

Here I use thor, which is not the most ideal method...


    git clone git@git.mostfit.in:mostfit.git
    git co new-layout

    rvm use 1.8.7  # install it if you haven't got it already
    rvm gemset create mostfit-new-layout
    rvm 1.8.7@mostfit-new-layout
    rvm rubygems 1.4.2

    # found this in install instructions
    gem install thor -v 0.9.9
    gem install dm-observer -v 0.10.1
    gem install uuid pdf-writer mongrel log4r

    sudo apt-get install libmysqlclient16-dev mysql-server

    thor merb:gem:redeploy
    thor merb:gem:install

    gem install uuid pdf-writer mongrel log4r i18n-translators-tools \
                i18n-translators-tools google-spreadsheet-ruby i18n \
                fastercsv rgettext roo

    cp config/example.database.yml config/database.yml
    vi config/database.yml

    bin/merb



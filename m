#!/usr/bin/env sh
ruby -e "pids = []; %x{ps ax}.each{|l| pids << l.split(' ')[0] if l =~ /merb/}; pids[0..-2].each{|pid| %x{kill -9 #{pid}} }"
./bin/merb $*

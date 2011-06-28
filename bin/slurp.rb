#! /usr/bin/env ruby

# Usage:
# slurp.rb dump_path db_name

# dump path is on mostfit.in
dump_path = ARGV[0]

# db_name is on the local machine
db_name   = ARGV[1] || File.basename(Dir.pwd)

# scp, and uncompress the database dump
sql_filename = File.basename(dump_path,".bz2")
bz2_filename = dump_path.split("/")[-1]
unless (File.exists?(sql_filename) or File.exists?(bz2_filename))
  fail "Failed to copy." unless system("scp mostfit.in:#{dump_path} .")
end
unless File.exists?(sql_filename)
  puts "Uncompressinging #{bz2_filename} ..."
  fail "Failed to uncompress" unless system("bunzip2 #{bz2_filename}")
end
# backup - defaults to no
print "Backup the current database? [y/N]: "
choice = $stdin.gets.chomp.downcase
system('./bin/dump.rb') if choice == 'y'

# now load the db
fail "Failed to load database dump." unless system("mysql -p -u root #{db_name} < #{sql_filename}")

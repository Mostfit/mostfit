#! /usr/bin/env ruby

# Usage:
# slurp.rb dump_path db_name

# dump path is on mostfit.in
require 'yaml'

pwd = `pwd`.split("/")[-1].chomp

dump_path = ARGV[0]
db_name   = ARGV[1]

# db_name is on the local machine
config  = YAML.load_file(File.join('config', 'database.yml'))
db_name ||= config['production']['database'] rescue nil

username = config['production']['username']
password = config['production']['password']


# scp, and uncompress the database dump
sql_filename = File.basename(dump_path,".bz2")
bz2_filename = dump_path.split("/")[-1]
unless (File.exists?(sql_filename) or File.exists?(bz2_filename))
  fail "Failed to copy." unless system("scp #{dump_path} .")
end
unless File.exists?(sql_filename)
  puts "Uncompressinging #{bz2_filename} ..."
  fail "Failed to uncompress" unless system("bunzip2 #{bz2_filename}")
end

# now load the db
if `pv -V`.empty?
  puts "no pv...sorry. continuing without progress bar"
  fail "Failed to load database dump." unless system("mysql -p -u root #{db_name} < #{sql_filename}")
else
  cmd = "pv #{sql_filename} | mysql -p#{password} -u root #{db_name}"
  puts "using #{cmd}"
  fail "Failed to load database dump." unless system(cmd)
end

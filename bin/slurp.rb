#! /usr/bin/env ruby

# Usage:
# slurp.rb dump_path db_name backup

# dump path is on mostfit.in
dump_path = ARGV[0]

# db_name is on the local machine
config  = YAML.load_file(File.join(mostfit_dir, 'config', 'database.yml'))
db_name   = ARGV[1] || config['development']['database']
backup    = ARGV[2] || false
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

# backup - defaults to no
if backup
  print "Backup the current database? [y/N]: "
  choice = $stdin.gets.chomp.downcase
  system('./bin/dump.rb') if choice == 'y'
end

# now load the db
user     = config['development']['username']
password = config['development']['password']
if `pv -V`.empty?
  puts "no pv...sorry. continuing without progress bar"
  fail "Failed to load database dump." unless system("mysql -p#{password} -u #{username} #{db_name} < #{sql_filename}")
else
  cmd = "pv #{sql_filename} | mysql -p#{password} -u #{username} #{db_name}"
  puts "using #{cmd}"
  fail "Failed to load database dump." unless system(cmd)
end

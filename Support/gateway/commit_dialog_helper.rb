#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../lib/git.rb'
status = Git::Status.new
git = Git.new
command = ARGV.shift
case command
when "revert"
  filepath = ARGV.shift
  File.open("/tmp/output", "wb") {|f| f.puts ARGV.inspect}
  git.revert(filepath)
  puts "\000      #{filepath}"
end


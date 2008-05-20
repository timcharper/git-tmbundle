#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../environment.rb'
git = Git.new
command = ARGV.shift
case command
when "revert"
  file_path = ARGV.shift
  File.open("/tmp/output", "wb") {|f| f.puts ARGV.inspect}
  git.revert(file_path)
  puts "\000      #{file_path}"
end


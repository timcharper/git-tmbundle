#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../environment.rb'
git = Git.new
command = ARGV.shift
case command
when "delete"
  file_path = ARGV.shift
  File.delete(git.path_for(file_path))
  puts "\000      #{file_path}asdf"
when "revert"
  file_path = ARGV.shift
  File.open("/tmp/output", "wb") {|f| f.puts ARGV.inspect}
  git.revert(file_path)
  puts "\000      #{file_path}"
end


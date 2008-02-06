# annotate gateway
require File.dirname(__FILE__) + '/../lib/git.rb'

filepath = ENV['TM_FILEPATH']
revision = ARGV[0]

git = SCM::Git::Annotate.new
log = SCM::Git::Log.new
annotations = git.annotate(filepath, revision)

if annotations.nil?
  puts "Error.  Aborting"
  abort
end

log_entries = log.log(filepath)

f = Formatters::Annotate.new
f.header("Annotations for ‘#{htmlize(git.shorten(filepath))}’")
f.content(annotations, log_entries, revision)

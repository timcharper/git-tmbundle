# annotate gateway
require File.dirname(__FILE__) + '/../lib/git.rb'

filepath = ENV['TM_FILEPATH']
revision = ARGV[0]

Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
git = SCM::Git::Annotate.new
annotations = git.annotate(filepath, revision)

if annotations.nil?
  puts "Error.  Aborting"
  abort
end

f = Formatters::Annotate.new(:selected_revision => revision, :as_partial => true)
f.header "Annotations for ‘#{htmlize(shorten(filepath))}’"
f.content annotations

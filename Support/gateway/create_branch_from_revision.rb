# annotate gateway
require File.dirname(__FILE__) + '/../lib/git.rb'
require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

revision = ARGV[0]
if revision.empty?
  TextMate::UI.alert(:warning, "Error", "You must specify a revision other than 'current'", 'OK') 
  abort
end

Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
git = SCM::Git.new

branch_name = TextMate::UI.request_string(:title => "Create Branch from revision #{revision}", :prompt => "What would you like to call this branch?")
abort if branch_name.blank?

output = git.command("branch", branch_name, revision)

if output.blank? # git returns nothing if successful
  TextMate::UI.alert(:informational, "Success!", "Branch has successfully been created!", 'OK') 
else
  TextMate::UI.alert(:warning, "Error!", "#{output}", 'OK') 
end  


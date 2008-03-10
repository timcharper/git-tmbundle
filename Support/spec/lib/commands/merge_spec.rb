require File.dirname(__FILE__) + '/../../spec_helper'

describe Git do
  before(:each) do
    @merge = Git.new
  end
  
  include SpecHelpers
  
  it "should extract conflicts from a merge" do
    result = @merge.parse_merge(<<-EOF)
Auto-merged project.txt
CONFLICT (content): Merge conflict in project.txt
Auto-merged dude.txt
CONFLICT (add/add): Merge conflict in dude.txt
CONFLICT (delete/modify): lib/file.rb deleted in HEAD and modified in release. Version release of lib/file.rb left in tree.
Auto-merged spec/fixtures/events.yml
CONFLICT (delete/modify): coso.txt deleted in release and modified in HEAD. Version HEAD of coso.txt left in tree.
Automatic merge failed; fix conflicts and then commit the result.
Automatic merge failed; fix conflicts and then commit the result.
EOF
    # puts result.inspect
    result[:conflicts].should == ["project.txt", "dude.txt", "lib/file.rb", "coso.txt"]
  end
end
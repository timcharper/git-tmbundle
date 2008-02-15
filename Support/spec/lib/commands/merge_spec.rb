require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Merge do
  before(:each) do
    @merge = SCM::Git::Merge.new
  end
  
  include SpecHelpers
  
  it "should extract conflicts from a merge" do
    result = @merge.parse_merge(<<-EOF)
Auto-merged project.txt
CONFLICT (content): Merge conflict in project.txt
Auto-merged dude.txt
CONFLICT (add/add): Merge conflict in dude.txt
Automatic merge failed; fix conflicts and then commit the result.
EOF
    # puts result.inspect
    result[:conflicts].should == ["project.txt", "dude.txt"]
  end
end
require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Branch do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
  end
  include SpecHelpers
  
  it "should list ignore (no branch)" do
    Git.command_response["branch"] = <<EOF
* (no branch)
  test_mod
EOF
    
    @git.branch.list_names.should == ["test_mod"]
  end
end

require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Submodule do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
  end
  include SpecHelpers
  
  it "should list submodules" do
    Git.command_response["submodule"] = <<EOF
 e741e43171fd34c98ef98afa5877fb2d74841b82 mod (undefined)
EOF
    
    @git.submodule.list.should == [{
      :revision => "e741e43171fd34c98ef98afa5877fb2d74841b82",
      :name     => "mod",
      :tag      => nil
    }]
  end
end

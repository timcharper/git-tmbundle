require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Submodule do
  before(:each) do
    @git = Git.new
    Git.reset_mock!
  end
  
  include SpecHelpers
  
  it "should return all submodules when listing one" do
    Git.command_response["ls-files", "--stage"] = <<EOF
160000 03a20cfe2e0e344f87ac3132ddc991899cef2567 0	vendor/plugins/fixture-scenarios
160000 e741e43171fd34c98ef98afa5877fb2d74841b82 0	vendor/plugins/mod
160000 b9276ab1ad9aee7c3688b365072fe0a616b68b71 0	vendor/plugins/railswhere
EOF
    submodules = @git.submodule.all
    submodules.should have(3).submodules
    
    submodules[0].revision.should == "03a20cfe2e0e344f87ac3132ddc991899cef2567"
    submodules[0].path.should == "vendor/plugins/fixture-scenarios"
    submodules[0].tag.should be_nil
    
    submodules[1].revision.should == "e741e43171fd34c98ef98afa5877fb2d74841b82"
    submodules[1].path.should == "vendor/plugins/mod"
    submodules[1].tag.should be_nil

    submodules[2].revision.should == "b9276ab1ad9aee7c3688b365072fe0a616b68b71"
    submodules[2].path.should == "vendor/plugins/railswhere"
    submodules[2].tag.should be_nil
  end
  
  it "should list all submodules in a given path when specified" do
    @git.should_receive(:command).with("ls-files", "--stage", "path/to/files").and_return("")
    @git.submodule.all(:path => "path/to/files")
  end
  
  it "should add a repository" do
    repo = "git@server:/repository.git"
    path = "my-path"
    Git.command_response["submodule", "add", "--", repo, path] = ""
    @git.submodule.add(repo, "/base/#{path}")
    Git.commands_ran.should == [["submodule", "add", "--", repo, path]]
  end
  
  describe "when working with a submodule" do
    before(:each) do
      @path = "vendor/plugins/acts_as_plugin"
      @submodule = SCM::Git::Submodule::SubmoduleProxy.new(@git, @git.submodule, :current_revision => "6789", :revision => "1234", :path => @path, :tag => "release")
      @submodule.stub!(:url).and_return("git@url.com/path/to/repo.git")
    end
    
    it "should cache" do
      File.should_receive(:exist?).with(@submodule.abs_path).and_return(true)
      File.should_receive(:exist?).with(@submodule.abs_cache_path).and_return(false)
      FileUtils.should_receive(:mkdir_p).with(File.join(@git.path, ".git/submodule_cache"))
      FileUtils.should_receive(:mv).with(@submodule.abs_path, @submodule.abs_cache_path, :force => true)
      @submodule.cache
    end
    
    it "should restore when submodule isn't in working copy" do
      Dir.should_receive(:has_a_file?).with(@submodule.abs_path).and_return(false)
      File.should_receive(:exist?).with(@submodule.abs_cache_path).and_return(true)
      FileUtils.should_receive(:mkdir_p).with(File.dirname(@submodule.abs_path))
      FileUtils.should_receive(:mv).with(@submodule.abs_cache_path, @submodule.abs_path, :force => true)
      @submodule.restore
    end
    
    it "should return a Git object for the submodule" do
      @git.should_receive(:with_path).with(File.join(@git.path, @path)).and_return(
        mock("git", :current_revision => "1234")
      )
      @submodule.git
    end
    
    it "should query it's current_revision when asked" do
      @submodule.stub!(:git).and_return stub("git", :current_revision => "1234")
      @submodule.current_revision(true).should == "1234"
    end
    
    it "should describe it's revision" do
      @submodule.git.should_receive(:describe).with("1234").and_return("tag-1234")
      @submodule.revision_description.should == "tag-1234"
    end
    
    it "should describe it's current revision" do
      @submodule.git.should_receive(:describe).with("6789").and_return("tag-6789")
      @submodule.current_revision_description.should == "tag-6789"
    end
    
    it "should be modified when current_revision and revision differ" do
      @submodule.stub!(:cloned?).and_return(true)
      @submodule.should be_modified
    end
    
    it "should be not modified when current_revision and revision are the same" do
      @submodule.stub!(:cloned?).and_return(true)
      @submodule.should_receive(:current_revision).and_return @submodule.revision
      @submodule.should_not be_modified
    end
    
    it "should not be modified if not yet checked out" do
      @submodule.stub!(:cloned?).and_return(false)
      @submodule.should_not_receive(:current_revision)
      @submodule.should_not be_modified
    end
    
    it "should not be cloned if the .git directory doesn't exist" do
      File.should_receive(:exist?).with(File.join(@submodule.abs_path, ".git")).and_return(false)
      @submodule.should_not be_cloned
    end
    
    it "should be cloned if the .git directory exists" do
      File.should_receive(:exist?).with(File.join(@submodule.abs_path, ".git")).and_return(true)
      @submodule.should be_cloned
    end
    
    it "should should be cached if abs_cache_path exists" do
      File.should_receive(:exist?).with(@submodule.abs_cache_path).and_return(true)
      @submodule.should be_cached
    end
    
    it "should call update on the submodule" do
      @submodule.update
      Git.commands_ran.should include(["submodule", "update", @submodule.path])
    end
  end
end

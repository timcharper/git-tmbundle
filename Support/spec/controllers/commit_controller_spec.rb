require File.dirname(__FILE__) + '/../spec_helper'

describe CommitController do
  include SpecHelpers
  before(:each) do
    Git.reset_mock!
    @controller = CommitController.singleton_new
    @git = Git.singleton_new
    Git.command_response["status"] = fixture_file("status_output.txt")
  end
  
  after(:each) do
    # puts Git.commands_ran.inspect
  end
  describe "normal commit (partial commit)" do
    before(:each) do
      @message = "My commit message"
      @git.should_receive(:merge_message).and_return(nil)
      @worker = PartialCommitWorker::Normal.singleton_new(@git)
      @worker.stub!(:show_commit_dialog).and_return([@message, ["file1.txt", "file2.txt"]])
      
      @git.should_receive(:commit).
        with("My commit message", ["file1.txt", "file2.txt"], :amend => false).
        and_return(:rev => "1234567")
        
      @git.should_receive(:diff).
        with(:path => ".", :revisions => "1234567^..1234567").
        and_return( Parsers.parse_diff(fixture_file("small.diff")) )
      
      @git.branch.stub!(:current_name).and_return("master")
      @output = capture_output do
        dispatch(:controller => "commit")
      end
    end
    
    after(:each) do
      # puts Git.commands_ran.inspect
    end
    
    it "should output the commit message" do
      @output.should include(@message)
    end
    
    it "should output the diff" do
      @output.should include("No newline at end of file")
    end
  end
  
  describe "Amend commit" do
    before(:each) do
      @message = "My commit message"
      @git.should_receive(:merge_message).and_return(nil)
      @worker = PartialCommitWorker::Amend.singleton_new(@git)
      @worker.stub!(:show_commit_dialog).and_return([@message, ["file1.txt", "file2.txt"]])
      
      @git.should_receive(:commit).
        with("My commit message", ["file1.txt", "file2.txt"], :amend => true).
        and_return(:rev => "1234567")
        
      @git.should_receive(:diff).
        with(:path => ".", :revisions => "1234567^..1234567").
        and_return( Parsers.parse_diff(fixture_file("small.diff")) )
        
      @git.branch.stub!(:current_name).and_return("master")
      
      @output = capture_output do
        dispatch(:controller => "commit", :type => "amend")
      end
    end
    
    after(:each) do
      # puts Git.commands_ran.inspect
    end
    
    it "should say mention we're amending a commit" do
      @output.should include("Amending")
    end
    
    it "should output the commit message" do
      @output.should include(@message)
    end
    
    it "should output the diff" do
      @output.should include("No newline at end of file")
    end
  end
  
  describe "when in the middle of a merge" do
    it "should run the mege dialog" do
      @merge_message = "Merged some branch into another branch..."
      @git.should_receive(:merge_message).twice.and_return(@merge_message)
      output = capture_output do
        dispatch(:controller => "commit")
      end
      output.should include(@merge_message)
    end
  end
  
  describe "when running a merge commit" do
    it "should run" do
      @merge_message = "Merged some branch into another branch..."
      output = capture_output do
        dispatch(:controller => "commit", :action => "merge_commit", :message => @merge_message)
      end
      output.should include(@merge_message)
    end
    
    it "should resolve auto add/rm merged files" do
      @merge_message = "Merged"
      @git.should_receive(:status).and_return([
         {:path => "/base/file.yml",          :status => {:short => "M", :long => "modified", :foreground =>"#eb6400", :background=>"#f7e1ad"}, :display=> "file.yml"},
         {:path => "/base/deleted_file.yml",  :status => {:short => "G", :long => "merged",   :foreground =>"#eb6400", :background=>"#f7e1ad"}, :display=> "deleted_file.yml"}
       ])
       @git.should_receive(:auto_add_rm).with(["deleted_file.yml"])
       output = capture_output do
         dispatch(:controller => "commit", :action => "merge_commit", :message => @merge_message)
       end
       output.should include(@merge_message)
    end
  end
end

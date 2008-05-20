require File.dirname(__FILE__) + '/../spec_helper'
describe AnnotateController do
  include SpecHelpers
  
  before(:each) do
    Git.reset_mock!
  end
  
  describe "when annotating" do
    before(:all) do
      Git.command_response["annotate", "file.rb"] = fixture_file("annotate.txt")
      Git.command_response["log", "file.rb"] = fixture_file("log_with_diffs.txt")
      @output = capture_output do 
        dispatch(:controller => "annotate", :file_path => "file.rb")
      end
      @h = Hpricot(@output)
      @log_options = (@h / "select[@name='rev'] / option")
    end
    
    it "should output the log" do
      @log_options.first.inner_text.should == "current"
      @log_options.length.should == 3
    end
    
    it "should output the annotation" do
      @output.should include("Author: Tim Harper")
    end
  end
end
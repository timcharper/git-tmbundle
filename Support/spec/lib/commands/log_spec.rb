require File.dirname(__FILE__) + '/../../spec_helper'

describe Git do  
  before(:each) do
    @git = Git.new
  end
  include SpecHelpers
  
  describe "when parsing a plain log" do
    before(:each) do
      @entries = @git.parse_log( fixture_file('log.txt'))
    end
    
    it "should parse out all items" do
      @entries.should have(5).entries
    end
    
    it "should parse out the author, msg, and revision" do
      result = @entries.first
      result[:rev].should == "2762e1264c439dced7f05eacd33fc56499b8b779"
      result[:author].should == "Tim Harper <timcharper@domain.com>"
      result[:date].should == Time.parse("Mon Feb 4 07:51:25 -0700 2008")
      result[:msg].should == %Q{bugfix - diff was not parsing the index line sometimes because it varies on deleted files

made more failproof}
    end
  end
  
  describe "when parsing a log with diffs" do
    before(:each) do
      @entries = @git.parse_log( fixture_file("log_with_diffs.txt"))
      @entry = @entries.first
    end
    
    it "should extract and parse diffs" do
      @entry[:diff].should_not be_nil
      @entry_diff = @entry[:diff].first
      @entry_diff[:left][:file_path].should == "Commands/Browse Annotated File (blame).tmCommand"
      @entry_diff[:right][:file_path].should == "Commands/Browse Annotated File (blame).tmCommand"
      @entry_diff[:lines].length.should == 19
    end
  end
  
end

require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Log do
  before(:all) do
    stub_command_runner(SCM::Git::Log)
  end
  
  before(:each) do
    @log = SCM::Git::Log.new
  end
  include SpecHelpers
  
  describe "when parsing a plain log" do
    before(:each) do
      @entries = @log.parse_log( fixture_file('log.txt'))
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
    
    it "should stringify results" do
      @log.stringify(@entries)
      @entries.first.keys.sort.should == ["author", "date", "msg", "rev"]
    end
  end
  
  describe "when parsing a log with diffs" do
    before(:each) do
      @entries = @log.parse_log( fixture_file("log_with_diffs.txt"))
      @entry = @entries.first

    end
    
    it "should extract and parse diffs" do
      @entry[:diff].should_not be_nil
      @entry_diff = @entry[:diff].first
      @entry_diff[:left][:filepath].should == "Commands/Browse Annotated File (blame).tmCommand"
      @entry_diff[:right][:filepath].should == "Commands/Browse Annotated File (blame).tmCommand"
      @entry_diff[:lines].length.should == 19
    end
  end
  
  describe "when running" do
    before(:each) do
      @log.command_output << fixture_file("log_with_diffs.txt")
      
      @output = capture_output do
        results = @log.run
      end
      @h = Hpricot(@output)
    end
    
    it_should_behave_like "Formatter with layout"
    
    it "should output the revision in short format" do
      rev_output = (@h / ".infobox > span > strong").first.to_s
      # rev_output.should include("Revision")
      rev_output.should match(/\b3dce1220\b/)
    end
    # puts htmlize(@output)
  end
end

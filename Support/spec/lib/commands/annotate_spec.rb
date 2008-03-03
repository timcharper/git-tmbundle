require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git do
  before(:each) do
    @annotate = Git.new
  end
  include SpecHelpers
  
  describe "when parsing a annotate" do
    TEST_ANNOTATE = File.read("#{FIXTURES_DIR}/annotate.txt")
    before(:each) do
      @lines = @annotate.parse_annotation(TEST_ANNOTATE)
    end
    
    it "should parse out all items" do
      @lines.should have(166).entries
    end
    
    it "should parse out the author, msg, and revision" do
      line = @lines.first
      line[:rev].should == "4c47a64b"
      line[:author].should == "duff"
      line[:date].should == Time.parse("2007-06-10 15:41:03 +0000")
      line[:text].should == "require ENV['TM_SUPPORT_PATH'] + '/lib/escape.rb'"
      
    end
  end
end

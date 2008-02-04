require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Diff do
  before(:each) do
    @log = SCM::Git::Log.new
  end
  describe "when parsing a log" do
    TEST_LOG = File.read("#{FIXTURES_DIR}/log.txt")
    before(:each) do
      @entries = @log.parse_log(TEST_LOG)
    end
    
    it "should parse out all items" do
      @entries.should have(5).entries
    end
    
    it "should parse out the author, msg, and revision" do
      result = @entries.first
      result[:revision].should == "2762e1264c439dced7f05eacd33fc56499b8b779"
      result[:author].should == "Tim Harper <timcharper@domain.com>"
      result[:date].should == Time.parse("Mon Feb 4 07:51:25 -0700 2008")
      result[:msg].should == <<-EOF
bugfix - diff was not parsing the index line sometimes because it varies on deleted files

made more failproof
EOF
    end
    
    it "should stringify results" do
      @log.stringify(@entries)
      @entries.first.keys.sort.should == ["author", "date", "msg", "revision"]
    end
  end
end

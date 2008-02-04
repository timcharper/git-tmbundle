require File.dirname(__FILE__) + '/../../spec_helper'

describe SCM::Git::Diff do
  before(:each) do
    @diff = SCM::Git::Diff.new
  end
  
  describe "when parsing a diff" do
    TEST_OUTPUT = File.read("#{FIXTURES_DIR}/changed_files.diff")
    before(:each) do
      @results = @diff.parse_diff(TEST_OUTPUT)
      @lines = @results.first[:lines]
    end
    
    it "should create an entry for each file" do
      @results.should have(2).results
      @results.map{|r| r[:left][:filepath]}.should == ["/Support/lib/commands/diff.rb", "/Support/lib/formatters/diff.rb"]
      @results.map{|r| r[:right][:filepath]}.should == ["/Support/lib/commands/diff.rb", "/Support/lib/formatters/diff.rb"]
    end
    
    it "should parse the line_numbers for the files" do
      @lines.map{|l| l[:ln_left]}.should == 
        (5..7).to_a + 
        [8] + 
        ([nil] * 20) + 
        (9..10).to_a + 
        [nil]
      
      @lines.map{|r| r[:ln_right]}.should == 
        (5..7).to_a + 
        [nil] + 
        (8..27).to_a + 
        (28..29).to_a + 
        [nil]
    end
    
    it "shouldn't count the (\\ No newline at end of file) line" do
      @lines.last[:text].should == "No newline at end of file"
      @lines.last[:ln_right].should == nil
      @lines.last[:ln_left].should == nil
    end
  end
  
  describe "when parse a diff with line breaks" do
    TEST_OUTPUT_BREAKS = File.read("#{FIXTURES_DIR}/changed_files_with_break.diff")
    before(:each) do
      @results = @diff.parse_diff(TEST_OUTPUT_BREAKS)
      @lines = @results.first[:lines]
    end
    
    it "should insert a line break" do
      @lines.map{|t| t[:type]}.should include(:cut)
    end
  end
end

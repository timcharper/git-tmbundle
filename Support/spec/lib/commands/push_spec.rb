require File.dirname(__FILE__) + '/../../spec_helper'

require 'stringio'

describe Git do
  include SpecHelpers
  
  before(:each) do
    @push = Git.new
    @push.version = "1.5.3"
  end
    
  describe "standard push" do
    TEST_INPUT = <<EOF
updating 'refs/heads/mybranch'
  from f0f27c95b7cdf4ca3b56ecb3c54ef3364133eb6a
  to   d8b368361ebdf2c51b78f7cfdae5c3044b23d189
 Also local refs/remotes/satellite/mybranch
updating 'refs/heads/satellite'
  from 60a254470cd97af3668ed4d6405633af850139c6
  to   746fba2424e6b94570fc395c472805625ab2ed25
 Also local refs/remotes/satellite/satellite
Generating pack...
Done counting 6 objects.
Deltifying 6 objects...
  16% (1/6) done\r 33% (2/6) done\r 50% (3/6) done\r 66% (4/6) done\r 83% (5/6) def done(args)
    
  end
  \r 100% (6/6) done\n
Writing 6 objects...
  16% (1/6) done\r 33% (2/6) done\r 50% (3/6) done\r 66% (4/6) done\r 83% (5/6) done\r 100% (6/6) done\n
Total 6 (delta 1), reused 0 (delta 0)
refs/heads/satellite: 60a254470cd97af3668ed4d6405633af850139c6 -> 746fba2424e6b94570fc395c472805625ab2ed25
refs/heads/mybranch: f0f27c95b7cdf4ca3b56ecb3c54ef3364133eb6a -> d8b368361ebdf2c51b78f7cfdae5c3044b23d189
EOF
  
    before(:each) do
      @process_io = StringIO.new(TEST_INPUT)
    end
  
    it "should call the status proc 6 times" do
      started_count = {}
      finished = {}
      output = {"Deltifying" => [], "Writing" => [] }
      @push.process_push(@process_io,
          :start => lambda { |state, count| started_count[state] = count },
          :progress => lambda {|state, percent, index, count| state; output[state] << [percent, index, count]},
          :end => lambda { |state, count| finished[state] = true }
      )
    
      for state in ["Deltifying", "Writing"]
        started_count[state].should == 6
        output[state].map{|o| o[0]}.should == [0,16,33,50,66,83,100]
        output[state].map{|o| o[1]}.should == (0..6).to_a
        output[state].map{|o| o[2]}.should == [6] * 7
        finished[state].should == true
      end
    end
  
    it "should return a list of all revisions pushed" do
      output = @push.process_push(@process_io)
      output[:pushes].should == {
        "refs/heads/satellite" => ["60a254470cd97af3668ed4d6405633af850139c6", "746fba2424e6b94570fc395c472805625ab2ed25"],
        "refs/heads/mybranch" => ["f0f27c95b7cdf4ca3b56ecb3c54ef3364133eb6a", "d8b368361ebdf2c51b78f7cfdae5c3044b23d189"]
      }
    end
  
    it "should return :nothing_to_push if Everything up-to-date" do
      output = @push.process_push(StringIO.new("Everything up-to-date\n"))
      output[:nothing_to_push].should == true
    end
  end
  
  describe "for git 1.5.4.3" do
    before(:each) do
      @process_io = StringIO.new(fixture_file("push_1_5_4_3_output.txt"))
      @push.version = "1.5.4.3"
    end

    it "should call the progress proc 6 times for state Compressing" do
      output = {"Compressing" => [], "Writing" => [] }

      @push.process_push(@process_io, :progress => lambda {|state, percent, index, count| output[state] << [percent, index, count]})
      output["Compressing"].map{|o| o[0]}.should == [50,100]
      output["Compressing"].map{|o| o[1]}.should == [1,2]
      output["Compressing"].map{|o| o[2]}.should == [2,2]
      output["Writing"].map{|o| o[0]}.should == [33,66,100]
      output["Writing"].map{|o| o[1]}.should == [1,2,3]
      output["Writing"].map{|o| o[2]}.should == [3,3,3]
    end

    it "should extract the push information for the branch and assume the current branch" do
      output = @push.process_push(@process_io)
      
      output[:pushes]['asdf'].should == ["865f920", "f9ca10d"]
      output[:pushes]['master'].should == nil

    end
  end
end

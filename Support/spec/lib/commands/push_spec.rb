require File.dirname(__FILE__) + '/../../spec_helper'

require 'stringio'

describe SCM::Git::Push do
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
  16% (1/6) done
  33% (2/6) done
  50% (3/6) done
  66% (4/6) done
  83% (5/6) done
 100% (6/6) done
Writing 6 objects...
  16% (1/6) done
  33% (2/6) done
  50% (3/6) done
  66% (4/6) done
  83% (5/6) done
 100% (6/6) done
Total 6 (delta 1), reused 0 (delta 0)
refs/heads/satellite: 60a254470cd97af3668ed4d6405633af850139c6 -> 746fba2424e6b94570fc395c472805625ab2ed25
refs/heads/mybranch: f0f27c95b7cdf4ca3b56ecb3c54ef3364133eb6a -> d8b368361ebdf2c51b78f7cfdae5c3044b23d189
EOF
  before(:each) do
    @process_io = StringIO.new(TEST_INPUT)
    @push = SCM::Git::Push.new
  end
  
  it "should call the status proc 6 times" do
    started_count = {}
    finished = {}
    output = {"Deltifying" => [], "Writing" => [] }
    @push.process_push(@process_io,
        :start => lambda { |state, count| started_count[state] = count },
        :progress => lambda {|state, percent, index, count| output[state] << [percent, index, count]},
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
  
  it "should return a list of all reivisions pushed" do
    output = @push.process_push(@process_io)
    output[:pushes].should == {
      "refs/heads/satellite" => ["60a254470cd97af3668ed4d6405633af850139c6", "746fba2424e6b94570fc395c472805625ab2ed25"],
      "refs/heads/mybranch" => ["f0f27c95b7cdf4ca3b56ecb3c54ef3364133eb6a", "d8b368361ebdf2c51b78f7cfdae5c3044b23d189"]
    }
  end
  
  it "should return :nothing_to_push if Everything up-to-date" do
    output = @push.process_push(StringIO.new(<<-EOF))
Everything up-to-date
EOF
    output[:nothing_to_push].should == true
  end
end

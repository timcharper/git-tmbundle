require File.dirname(__FILE__) + '/../../spec_helper'

require 'stringio'

describe SCM::Git::Pull do
  include SpecHelpers
  TEST_INPUT = <<EOF
Unpacking 6 objects...
 16% (1/6) done\r 33% (2/6) done\r 50% (3/6) done\r 66% (4/6) done\r 83% (5/6) done\r 100% (6/6) done\n
* refs/remotes/origin/master: fast forward to branch 'master' of /Users/timcharper/projects/origin
  old..new: a58264f..89e8f37
* refs/remotes/origin/mybranch: storing branch 'mybranch' of /Users/timcharper/projects/origin
  commit: d8b3683
You asked me to pull without telling me which branch you
want to merge with, and 'branch.asdf.merge' in
your configuration file does not tell me either.  Please
name which branch you want to merge on the command line and
try again (e.g. 'git pull <repository> <refspec>').
See git-pull(1) for details on the refspec.

If you often merge with the same branch, you may want to
configure the following variables in your configuration
file:
EOF
  before(:all) do
    stub_command_runner(SCM::Git::Log)
    stub_command_runner(SCM::Git::Pull)
  end
  
  before(:each) do
    @process_io = StringIO.new(TEST_INPUT)
    @pull = SCM::Git::Pull.new
  end
  
  it "should call the status proc 6 times" do
    started_count = {}
    finished = {}
    output = {"Unpacking" => [] }
    @pull.process_pull(@process_io,
        :start => lambda { |state, count| started_count[state] = count },
        :progress => lambda {|state, percent, index, count| output[state] << [percent, index, count]},
        :end => lambda { |state, count| finished[state] = true }
    )
    
    for state in ["Unpacking"]
      started_count[state].should == 6
      output[state].map{|o| o[0]}.should == [0,16,33,50,66,83,100]
      output[state].map{|o| o[1]}.should == (0..6).to_a
      output[state].map{|o| o[2]}.should == [6] * 7
      finished[state].should == true
    end
  end
  
  it "should return a list of all revisions pulled" do
    output = @pull.process_pull(@process_io)
    output[:pulls].should == {
      "refs/remotes/origin/master" => ["a58264f", "89e8f37"],
      "refs/remotes/origin/mybranch" => ["d8b3683^", "d8b3683"]
    }
  end
  
  it "should return :nothing_to_pull if Everything up-to-date" do
    output = @pull.process_pull(StringIO.new(<<-EOF))
Already up-to-date.
EOF
    output[:nothing_to_pull].should == true
  end
  
  it "should run" do
    SCM::Git::Pull.command_output << %Q{origin}
    SCM::Git::Pull.command_output << TEST_INPUT
    SCM::Git::Log.command_output << fixture_file("log_with_diffs.txt")
    SCM::Git::Log.command_output << fixture_file("log_with_diffs.txt")
    capture_output do
      @pull.run
    end
  end
end

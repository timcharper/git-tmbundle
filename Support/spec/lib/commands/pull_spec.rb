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
  before(:each) do
    @process_io = StringIO.new(TEST_INPUT)
    @pull = Git::Pull.new
    Git.reset_mock!
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
  
  it "should run and output log of changes pulled" do
    # query the sources
    Git.command_response["branch"] = "* master\n"
    Git.command_response["branch", "-r"] = "  origin/master\n  origin/release\n"
    Git.command_response["config", "remote.origin.fetch"] = "+refs/heads/*:refs/remotes/origin/*"
    Git.command_response["config", "branch.master.remote"] = %Q{origin}
    Git.command_response["config", "branch.master.merge"] = %Q{refs/heads/master}
    Git.command_response["remote"] = %Q{origin}
    
    # query the config - if source != self["remote.#{current_branch}.remote"] || self["remote.#{current_branch}.merge"].nil?
    
    # Git.command_response[] 
    Git.command_response["log", "-p", "a58264f..89e8f37", "."] = fixture_file("log_with_diffs.txt")
    Git.command_response["log", "-p", "d8b3683^..d8b3683", "."] = fixture_file("log_with_diffs.txt")
    Git.command_response["pull", "origin"] = TEST_INPUT
    output = capture_output do
      @pull.run
    end
    
    output.should include("Log of changes pulled")
  end
end

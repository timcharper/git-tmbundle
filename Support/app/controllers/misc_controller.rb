class MiscController < ApplicationController
  layout "application", :only => [:init]
  def init
    puts "<h2>Initializing Git Repository in #{ENV['TM_PROJECT_DIRECTORY']}</h2>"
    puts htmlize(git.init(ENV["TM_PROJECT_DIRECTORY"]))
  end
  
  def gitk
    run_detached("PATH=#{File.dirname(git.git)}:$PATH && gitk --all", "Wish Shell")
  end
  
  def gitgui
    run_detached("PATH=#{File.dirname(git.git)}:$PATH && git gui", "Git Gui")
  end
  
  def gitnub
    cmd = first_which(git.config["git-tmbundle.gitnub-path"], "nub", "/Applications/GitNub.app/Contents/MacOS/GitNub")
    if cmd
      run_detached(cmd + " #{ENV['TM_PROJECT_DIRECTORY']}", "Gitnub")
    else
      puts "Unable to find Gitnub.  Use the config dialog to set the Gitnub path to where you've installed it."
      output_show_tool_tip
    end
  end
  
  def gitx
    cmd = first_which(git.config["git-tmbundle.gitx-path"], "gitx", "/Applications/GitX.app/Contents/Resources/gitx")
    if cmd
      run_detached("cd '#{ENV['TM_DIRECTORY']}';" + cmd, "GitX")
    else
      puts "Unable to find GitX.  Use the config dialog to set the GitX path to where you've installed it."
      output_show_tool_tip
    end
  end
  
  protected
    def first_which(*args)
      args.map do |arg|
        next if arg.blank?
        result = `which '#{arg}'`.strip
        return result unless result.empty?
      end
      nil
    end
    
    def run_detached(cmd, app_name)
      exit if fork            # Parent exits, child continues.
      Process.setsid          # Become session leader.
      exit if fork            # Zap session leader.

      # After this point you are in a daemon process
      pid = fork do
        STDOUT.reopen(open('/dev/null'))
        STDERR.reopen(open('/dev/null'))
        Thread.new do
          sleep 1.5
          %x{osascript -e 'tell app "#{app_name}" to activate'}
          exit
        end
        system(cmd)
      end

      Process.detach(pid)
      #inspired by http://andrejserafim.wordpress.com/2007/12/16/multiple-threads-and-processes-in-ruby/
    end
  
end
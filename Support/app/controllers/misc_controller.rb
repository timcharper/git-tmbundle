class MiscController < ApplicationController
  def init
    puts "<h2>Initializing Git Repository in #{ENV['TM_PROJECT_DIRECTORY']}</h2>"
    puts htmlize(git.init(ENV["TM_PROJECT_DIRECTORY"]))
  end
  
  def gitk
    wishish_command("gitk --all", "Wish Shell")
  end
  
  def gitgui
    wishish_command("git-gui", "Git Gui")
  end
  
  protected
    def wishish_command(cmd, app_name)
      exit if fork            # Parent exits, child continues.
      Process.setsid          # Become session leader.
      exit if fork            # Zap session leader.

      # After this point you are in a daemon process
      fork do
        STDOUT.reopen(open('/dev/null'))
        STDERR.reopen(open('/dev/null'))
        Dir.chdir(git.paths.first)
        Thread.new do
          sleep 0.25
          %x{osascript -e 'tell app "#{app_name}" to activate'}
        end
        system(cmd)
      end

      Process.detach(pid)
      #inspired by http://andrejserafim.wordpress.com/2007/12/16/multiple-threads-and-processes-in-ruby/
    end
  
end
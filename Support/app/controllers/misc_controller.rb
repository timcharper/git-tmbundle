class MiscController < ApplicationController
  def init
    puts "<h2>Initializing Git Repository in #{ENV['TM_PROJECT_DIRECTORY']}</h2>"
    puts htmlize(git.init(ENV["TM_PROJECT_DIRECTORY"]))
  end
  
  def gitk
    exit if fork            # Parent exits, child continues.
    Process.setsid          # Become session leader.
    exit if fork            # Zap session leader.

    # After this point you are in a daemon process
    fork do
      
      STDOUT.reopen(open('/dev/null'))
      STDERR.reopen(open('/dev/null'))
      Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
      Thread.new do
        sleep 0.05
        %x{osascript -e 'tell app "Wish Shell" to activate'}
      end
      %x{gitk --all}
    end

    Process.detach(pid)

    #copied from http://andrejserafim.wordpress.com/2007/12/16/multiple-threads-and-processes-in-ruby/
  end
  
  def gitgui
    exit if fork            # Parent exits, child continues.
    Process.setsid          # Become session leader.
    exit if fork            # Zap session leader.

    # After this point you are in a daemon process
    fork do
      STDOUT.reopen(open('/dev/null'))
      STDERR.reopen(open('/dev/null'))
      Dir.chdir(ENV['TM_PROJECT_DIRECTORY'])
      %x{git-gui}
    end

    Process.detach(pid)
  end
  
end
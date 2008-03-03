CW = ENV['TM_SUPPORT_PATH'] + '/bin/CommitWindow.app/Contents/MacOS/CommitWindow'

class CommitController < ApplicationController
  def index
    if git.clean_directory?
      puts "Working directory is clean (nothing to commit)"
      exit
    end
    
    if git.merge_message
      @status = git.status
      @message = git.merge_message 
      render "merge_commit"
    else
      run_partial_commit
    end
  end
  
  def merge_commit
    message = params[:message]
    f = Formatters::Commit.new
    statuses = git.status(git.git_base)
    files = statuses.map { |status_options| (status_options[:status][:short] == "G") ? git.make_local_path(status_options[:path]) : nil }.compact

    auto_add_rm(files)
    res = git.commit(message, [])
    f.output_commit_result(res)
  end
  
  protected
      
    def run_partial_commit
      f = Formatters::Commit.new
      target_file_or_dir = git.paths.first
      f.header "Committing Files in ‘#{htmlize(shorten(target_file_or_dir))}’"
      flush

      files, statuses = [], []
      git.status(target_file_or_dir).each do |e|
        files  << e_sh(shorten(e[:path], @base))
        statuses << e_sh(e[:status][:short])
      end
    
      msg, files = show_commit_dialog(files, statuses)

      puts "<h2>Commit Files:</h2><ul>"
      puts files.map { |e| "<li>#{htmlize(e)}</li>\n" }.join
      puts "</ul>"

      puts "<h2>Using Message:</h2>"
      puts "<pre>#{htmlize(msg)}</pre>"
      STDOUT.flush

      unless files.empty?
        puts "<h2>Result:</h2>"
        auto_add_rm(files)
        res = git.commit(msg, files)
        f.output_commit_result(res)
      end
    end
    
    def show_commit_dialog(files, statuses)
      status_helper_tool = ENV['TM_BUNDLE_SUPPORT'] + '/gateway/commit_dialog_helper.rb'
      
      res = %x{#{e_sh CW}                 \
        --diff-cmd   '#{git.git},diff'        \
        --action-cmd "M,D:Revert,#{status_helper_tool},revert" \
        --status #{statuses.join ':'}       \
        #{files.join ' '} 2>/dev/console
      }

      if $? != 0
        puts "<strong>Cancel</strong>"
        abort
      end

      res   = Shellwords.shellwords(res)
      msg = res[1]
      files = res[2..-1]
      return msg, files
    end
    
    def auto_add_rm(files)
      git.chdir_base
      add_files = files.select{ |f| File.exists?(f) }
      remove_files = files.reject{ |f| File.exists?(f) }
      res = git.add(add_files) unless add_files.empty?
      res = git.rm(remove_files) unless remove_files.empty?
    end
end
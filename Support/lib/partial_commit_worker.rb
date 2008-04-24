module PartialCommitWorker
  class NotOnBranchException < Exception; end
  class NothingToCommitException < Exception; end
  class CommitCanceledException < Exception; end
  
  def self.factory(_type, *args)
    klass = case _type
    when "amend" then
      PartialCommitWorker::Amend
    else
      PartialCommitWorker::Normal
    end
    
    klass.new(*args)
  end
  
  class Base
    attr_reader :git
    
    def initialize(git)
      @git = git
      @base = git.git_base
    end
  
    def ok_to_proceed_with_partial_commit?
      (! git.branch.current_name.nil?) || git.initial_commit_pending?
    end
    
    def target_file_or_dir
      @target_file_or_dir ||= git.paths.first
    end
    
    def show_commit_dialog(files, statuses)
      status_helper_tool = ENV['TM_BUNDLE_SUPPORT'] + '/gateway/commit_dialog_helper.rb'
      
      res = %x{#{e_sh CW}                 \
        --diff-cmd   '#{git.git},diff'        \
        --action-cmd "M,D:Revert,#{status_helper_tool},revert" \
        --status #{statuses.join ':'}       \
        #{files.join ' '} 2>/dev/console
      }

      raise CommitCanceledException if $? != 0

      res   = Shellwords.shellwords(res)
      msg = res[1]
      files = res[2..-1]
      return msg, files
    end
    
    def run
      raise NotOnBranchException unless ok_to_proceed_with_partial_commit?
      
      files, statuses = [], []
      git.status(target_file_or_dir).each do |e|
        files  << e_sh(shorten(e[:path], @base))
        statuses << e_sh(e[:status][:short])
      end
      
      raise NothingToCommitException if files.empty?
    
      msg, files = show_commit_dialog(files, statuses)

      git.auto_add_rm(files)
      res = git.commit(msg, files, :amend => amend)
      { :files => files, :message => msg, :result => res}
    end
    
    def title
      "#{title_prefix} in ‘#{htmlize(shorten(target_file_or_dir, ENV['TM_PROJECT_DIRECTORY'] || @base))}’ on branch ‘#{htmlize(git.branch.current_name)}’"
    end
  end
  
  class Normal < Base
    def title_prefix
      "Committing Files"
    end
    
    def amend
      false
    end
  end
  
  class Amend < Base
    def title_prefix
      "Amending the commit"
    end
    
    def amend
      true
    end
  end
end

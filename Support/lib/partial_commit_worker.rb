# encoding: utf-8

CW = ENV['TM_SUPPORT_PATH'] + '/bin/CommitWindow.app/Contents/MacOS/CommitWindow'

module PartialCommitWorker
  class NotOnBranchException < Exception; end
  class NothingToCommitException < Exception; end
  class CommitCanceledException < Exception; end
  
  def self.factory(_type, *args)
    klass = (_type == "amend" ? PartialCommitWorker::Amend : PartialCommitWorker::Normal)
    klass.new(*args)
  end
  
  class Base
    attr_reader :git
    
    def initialize(git)
      @git = git
      @base = git.path
    end
  
    def ok_to_proceed_with_partial_commit?
      (! git.branch.current_name.nil?) || git.initial_commit_pending?
    end
    
    def target_paths
      @target_paths ||= git.paths
    end
    
    def split_file_statuses
      [file_candidates.map{ |fc| fc[0] }, file_candidates.map{ |fc| fc[1] }]
    end
    
    def status_helper_tool
      ENV['TM_BUNDLE_SUPPORT'] + '/gateway/commit_dialog_helper.rb'
    end
        
    def exec_commit_dialog
      files, statuses = split_file_statuses
      
      res = %x{cd "#{git.path}" && #{e_sh CW}                 \
        --diff-cmd   '#{git.git},diff'        \
        --action-cmd "M,D:Revert,#{status_helper_tool},revert" \
        --action-cmd "?:Delete,#{status_helper_tool},delete" \
        --status #{statuses.join(':')}       \
        #{files.map{ |f| e_sh(f) }.join(' ')} 2>/dev/console
      }
      canceled = ($? != 0)
      res   = Shellwords.shellwords(res)
      msg = res[1]
      files = res[2..-1]
      return canceled, msg, files
    end
    
    def show_commit_dialog
      canceled, msg, files = exec_commit_dialog
      raise CommitCanceledException if canceled
      [msg, files]
    end
    
    def file_candidates
      @file_candidates ||= 
        git.status(target_paths).map do |e|
          [shorten(e[:path], @base), e[:status][:short]]
        end
    end
    
    def run
      raise NotOnBranchException unless ok_to_proceed_with_partial_commit?
      raise NothingToCommitException if nothing_to_commit?
    
      msg, files = show_commit_dialog
      
      git.auto_add_rm(files)
      res = git.commit(msg, files, :amend => amend)
      { :files => files, :message => msg, :result => res}
    end
    
    def title
      "#{title_prefix} in #{target_paths.map { |e| htmlize("‘" + shorten(e, ENV['TM_PROJECT_DIRECTORY'] || @base) + "’") } * ', '} on branch ‘#{htmlize(git.branch.current_name)}’"
    end
    
    def nothing_to_commit?
      file_candidates.empty?
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
    COMMIT_MESSAGE_FILENAME = "-- update commit message --"
    
    def title_prefix
      "Amending the commit"
    end
    
    def amend
      true
    end
    
    def show_commit_dialog(*args)
      msg, files = super(*args)
      if files.first==COMMIT_MESSAGE_FILENAME
        files.shift
      else
        msg = ""
      end
      msg = git.log(:limit => 1).first[:msg] if msg.strip.empty?
      
      [msg, files]
    end
    
    def file_candidates
      return @file_candidates if @file_candidates
      super
      @file_candidates.unshift([COMMIT_MESSAGE_FILENAME, "M"])
      @file_candidates
    end
  end
end
 
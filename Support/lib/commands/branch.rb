class SCM::Git::Branch < SCM::Git::CommandProxyBase
  module BranchHelperMethods
    def shorten(name)
      name && name.gsub(/refs\/(heads|remotes)\//, "")
    end
    
    def format_name(name, format = :short)
      (format == :short || format == nil) ? shorten(name) : name
    end
  end
  
  include BranchHelperMethods
  
  def [](name)
    SCM::Git::Branch::BranchProxy.new(@base, self, name)
  end
  
  def create_and_switch(name)
    base.command("checkout", "-b", name)
  end
  
  def create(name, options = {})
    args = ["branch"]
    args << "--track" if options[:autotrack]
    args << name
    case
    when ! options[:source].blank?
      args << options[:source]
    when ! options[:tag].blank?
      args << options[:tag]
    when ! options[:revision].blank?
      args << options[:revision]
    end
    base.command(*args)
  end
  
  def switch(name)
    result = base.command("checkout", name)
    rescan_project
    result
  end
  
  def all_for_local_or_remote(which, options = {})
    list(which, options).map do |branch_params| 
      BranchProxy.new(@base, self, branch_params)
    end
  end
  
  def all(which = :both, options = {})
    branches = []
    which = [:local, :remote] if which == :both
    [which].flatten.each do |side|
      branches.concat all_for_local_or_remote(side, options)
    end
    
    branches.compact
  end
  
  def list(which = :local, options= {})
    params = []
    case which
    when :local then params << "refs/heads"
    when :remote then params << "refs/remotes"
    end
    result = base.command("for-each-ref", *params).split("\n").map do |e|
      next unless /^([a-f0-9]{40})\s*commit\s*(.+)$/.match(e)
      {:ref => $1, :name => $2}
    end.compact
    
    if options[:remote]
      r_prefix = @base.remote[options[:remote]].remote_branch_prefix
      result.delete_if { |r| r[:name][0..(r_prefix.length-1)] != r_prefix }
    end
    result
  end
  
  def list_names(which = :local, options = {})
    list(which, options).map do |b|
      format_name(b[:name], options[:format])
    end
  end
  
  alias names list_names
  
  def current
    _current_name = current_name(:long)
    list(:local).each do |branch_params|
      return BranchProxy.new(@base, self, branch_params) if branch_params[:name] == _current_name
    end
    
    nil
  end
  
  def current_name(format = :short)
    return unless /^ref: (.+)$/.match(File.read(@base.path_for(".git/HEAD")))
    format_name($1, format)
  rescue
    nil
  end
  
  def delete(name, options = {})
    branch_type = options[:branch_type] || (name.include?("/") ? :remote : :local)
    case branch_type.to_sym
    when :remote then delete_remote(name, options)
    when :local then delete_local(name, options)
    else
      raise "Unknown branch type: #{branch_type}"
    end
  end
  
  def delete_local(name, options = {})
    
    output = base.command("branch", options[:force] ? "-D" : "-d", name).strip
    outcome = case output
      when /^Deleted branch #{name}/
        :success
      when /error.+(not a strict subset|not an ancestor of your current HEAD)/
        :unmerged
      else
        :unknown
      end
    {:outcome => outcome, :output => output, :branch => name }
  end
  
  def delete_remote(name, options = {})
    remote, branch = name.split("/")
    output = base.command("push", remote, ":#{branch}")
    outcome = case output
    when /refs\/heads\/#{branch}: .+\-\> deleted/, /\[deleted\]/
      :success
    when /error: dst refspec .+ does not match any existing ref on the remote and does not start with refs\/./
      :branch_not_found
    else
      :unknown
    end
    { :outcome => outcome, :output => output, :remote => remote, :branch => branch }
  end
  
  def compare_status(left, right)
    new_commits = Hash.new(0)
    result = @base.command("rev-list", "--left-right", "#{left}...#{right}").split("\n").each do |line|
      case line[0..0]
      when "<"
        new_commits[:left] += 1
      when ">"
        new_commits[:right] += 1
      end
    end
    
    case
    when new_commits[:left] == 0 && new_commits[:right] == 0
      :same
    when new_commits[:left] == 0 && new_commits[:right] >= 0
      :behind
    when new_commits[:left] >= 0 && new_commits[:right] == 0
      :ahead
    else
      :diverged
    end
  end
  
  class BranchProxy
    include BranchHelperMethods
    attr_reader :ref
    
    def initialize(base, parent, options = {})
      @base = base
      @parent = parent
      @name = options[:name]
      @ref = options[:ref]
    end
  
    def name(format = :short)
      format_name(@name, format)
    end
    
    def local?
      @local ||= (@name[0..10] == "refs/heads/")
    end
  
    def current?
      @parent.current_name(:long) == name(:long)
    end
  
    def remote?
      ! @local
    end
  
    def default?
      raise "implement me"
    end
    
    def remote(reload = false)
      remote_name(reload) && @base.remote[remote_name]
    end
    
    def remote_name(reload = false)
      @remote_name = nil if reload
      @remote_name ||= @base.config["branch.#{name}.remote"]
    end
  
    def remote_name=(value)
      @remote_name, @tracking_branch_name = nil
      @base.config["branch.#{name}.remote"] = value
    end
  
    def merge(reload = false)
      @merge = nil if (reload)
      @merge ||= @base.config["branch.#{name}.merge"]
    end
  
    def merge=(value)
      @merge, @tracking_branch_name = nil
      @base.config["branch.#{name}.merge"] = value
    end
    
    def tracking_branch_name(format = :short)
      @tracking_branch_name ||= (remote && merge && remote.remote_branch_name_for(merge, :long))
      format_name(@tracking_branch_name, format)
    end
    
    # tell if a branch 
    def tracking_status
      return unless tracking_branch_name(:long)
      @parent.compare_status(name(:long), tracking_branch_name(:long))
    end
  end
end


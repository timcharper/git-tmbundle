class SCM::Git::Branch < SCM::Git::SubmoduleBase
  
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
    base.chdir_base
    result = base.command("checkout", name)
    rescan_project
    result
  end
  
  def list(which = :local, options= {})
    params = []
    case which
    when :all then params << "-a"
    when :remote then params << "-r"
    end
    
    result = base.command("branch", *params).split("\n").map { |e| { :name => e[2..-1], :default => e[0..1] == '* ' } }
    if options[:remote_name]
      r_prefix = remote_branch_prefix(options[:remote_name])
      result.delete_if {|r| ! Regexp.new("^#{Regexp.escape(r_prefix)}\/").match(r[:name]) }
    end
    result
  end
  
  def list_names(*args)
    list(*args).map{|b| b[:name]}
  end
  
  def current
    list.find { |b| b[:default] }
  end
  
  def current_name
    current[:name]
  end

  def remote_branch_prefix(remote_name)
    /\*:refs\/remotes\/(.+)\/\*/.match(base.config["remote.#{remote_name}.fetch"])
     $1
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
      when "Deleted branch #{name}."
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
end
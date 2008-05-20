class DiffController < ApplicationController
  
  def diff
    show_diff_title unless params[:layout].to_s=="false"
    @rev = params[:rev]
    @title = params[:title] || "Uncomitted changes"
    params[:context_lines] = git.config["git-tmbundle.log.context-lines"] if git.config["git-tmbundle.log.context-lines"]
    render("_diff_results", :locals => {
      :diff_results => git.diff(params.filter(:path, :revision, :context_lines, :revisions, :branches, :tags, :since))
    })
  end
  
  def uncommitted_changes
    paths = case
      when params[:path] 
        [params[:path]]
      else
        git.paths(:fallback => :current_file, :unique => true)
      end
    base = git.git_base
    puts "<h2>Uncommitted Changes for ‘#{htmlize(paths.map{|path| shorten(path, base)} * ', ')}’</h2>"
    open_in_tm_link
    
    paths.each do |path|
      render("_diff_results", :locals => {:diff_results => git.diff(:path => path, :since => "HEAD") })
    end
  end
  
  def compare_revisions
    filepaths = git.paths.first
    if filepaths.length > 1
      base = git.nca(filepaths)
    else 
      base = filepaths.first
    end
    
    log = LogController.new
    revisions = log.choose_revision(base, "Choose revisions for #{filepaths.map{|f| git.make_local_path(f)}.join(',')}", :multiple, :sort => true)

    if revisions.nil?
      puts "Canceled"
      return
    end
    
    render_component(:controller => "diff", :action => "diff", :revisions => revisions, :path => base)
  end
  
protected
  def open_in_tm_link
    puts <<-EOF
      <a href='txmt://open?url=file://#{e_url '/tmp/output.diff'}'>Open diff in TextMate</a>
    EOF
  end
  
  def show_diff_title
    puts "<h2>"
    case
    when params[:branches]
      branches = params[:branches]
      branches = branches.split("..") if params[:branches].is_a?(String)
      puts "Comparing branches #{branches.first}..#{branches.last}"
    when params[:revisions]
      revisions = params[:revisions]
      revisions = revisions.split("..") if params[:revisions].is_a?(String)
      puts "Comparing branches #{revisions.first}..#{revisions.last}"
    end
    puts "</h2>"
  end
  
  def extract_diff_params(params)
    diff_params = params.dup.delete_if do |key, value|
      ! [:revisions, :revision, :branches, :tags, :path].include?(key)
    end
    diff_params[:context_lines] = git.config["git-tmbundle.log.context-lines"] if git.config["git-tmbundle.log.context-lines"]
    diff_params
  end
end

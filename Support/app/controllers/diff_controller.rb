class DiffController < ApplicationController
  
  def diff
    @rev = params[:rev]
    @title = params[:title] || "Uncomitted changes"
    
    render("_diff_results", :locals => {:diff_results => git.diff(params)})
  end
  
  def uncommitted_changes
    paths = case
      when params[:path] 
        [params[:path]]
      else
        git.paths(:fallback => :current_file, :unique => true)
      end
    base = git.nca(paths)
    @title = "Uncomitted Changes for ‘#{htmlize(paths.map{|path| shorten(path, base)} * ', ')}’"
    open_in_tm_link
    
    paths.each do |path|
      render("_diff_results", :locals => {:diff_results => git.diff(:file => path) })
    end
  end
  
protected
  def open_in_tm_link
    puts <<-EOF
      <a href='txmt://open?url=file://#{e_url '/tmp/output.diff'}'>Open diff in TextMate</a>
    EOF
  end

end
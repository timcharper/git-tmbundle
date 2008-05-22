module DiffHelper
  def extract_submodule_revisions(diff_result)
    diff_result[:lines].map do |line| 
      line[:text].gsub("Subproject commit ", "")
    end
  end
end
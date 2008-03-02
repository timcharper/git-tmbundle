class String
  def constantize
    Object.module_eval("::" + self)
  end
  
  def underscore
    gsub(/(^|\b)[A-Z]/) { |l| l.downcase}.gsub(/[A-Z]/) { |l| "_#{l.downcase}" }.gsub("::", "/")
  end
  
  def classify
    gsub(/^[a-z]/) { |l| l.upcase}.gsub(/_[a-z]/) { |l| l[1..1].upcase}.gsub(/\b[a-z]/) {|l| l.upcase}.gsub("/", "::")
  end
end
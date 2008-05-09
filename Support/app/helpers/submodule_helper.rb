module SubmoduleHelper
  module Update
    def with_submodule_cacheing(&block)
      git.submodule.all.each { |m| m.cache }
      begin
        yield
      ensure
        new_modules = git.submodule.all
        new_modules.each { |m| m.restore }
      end
      
      unless new_modules.empty?
        puts "<br /><br /><h3>Updating submodules</h3>"
        puts htmlize(git.submodule.init_and_update)
      end
    end
  end
end
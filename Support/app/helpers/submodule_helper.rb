module SubmoduleHelper
  module Update
    def with_submodule_stashing(&block)
      git.submodule.all.each { |m| m.stash }
      begin
        yield
      ensure
        git.submodule.all.each { |m| m.restore }
      end
      
      update_submodules_si_hay
    end
    
    def update_submodules_si_hay
      unless git.submodule.all.empty?
        puts "<br /><br /><h3>Updating submodules</h3>"
        puts htmlize(git.submodule.init_and_update)
      end
    end
  end
end
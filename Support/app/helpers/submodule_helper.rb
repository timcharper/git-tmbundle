module SubmoduleHelper
  module Update
    def update_submodules_si_hay
      unless git.submodule.all.empty?
        puts "<br /><br /><h3>Updating submodules</h3>"
        puts htmlize(git.submodule.init_and_update)
      end
    end
  end
end
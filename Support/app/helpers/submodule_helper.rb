module SubmoduleHelper
  module Update
    def with_submodule_updating(&block)
      old_modules = get_submodule_hash
      begin
        yield
      ensure
        new_modules = get_submodule_hash
        
        submodule_paths = (new_modules.keys + old_modules.keys).sort.uniq
        return if submodule_paths.empty?
        puts "<br /><br /><h2>Updating submodules</h2>"
        submodule_paths.each do |path|
          old_module, new_module = old_modules[path], new_modules[path]
          case
          when old_module && ! new_module
            puts "<h3>Cacheing submodule #{old_module.path.inspect} because it doesn't exist in this branch</h3>"
            old_module.cache
          when new_module && ! old_module
            puts "<h3>Restoring submodule #{new_module.path.inspect} from cache.</h3>"
            new_module.restore
            update_submodule(new_module) if new_module.modified?
          when ! old_module.modified? && new_module.modified?
            update_submodule(new_module)
          when new_module.modified? && old_module.modified?
            puts "<h3>Not updating submodule #{new_module.path.inspect}, because it's revision pointer change isn't committed."
          end
        end
      end
    end
    
    def get_submodule_hash
      git.submodule.all.inject({}) { |h, sm| h[sm.path] = sm; h }
    end
    
    def update_submodule(submodule)
      puts "<h3>Updating submodule #{submodule.path}</h3>"
      puts "<pre>#{h submodule.update}</pre>"
      flush
    end
  end
  
  def render_submodule_header(submodule)
    puts "<h3>... in submodule ‘#{link_to_mate(submodule.path, submodule.git.path)}’</h3>"
  end
end
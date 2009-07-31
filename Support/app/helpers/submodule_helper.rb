# encoding: utf-8

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
        submodule_paths.each do |path|
          old_module, new_module = old_modules[path], new_modules[path]
          case
          when old_module && old_module.modified?
            puts "<h3>Not updating submodule #{new_module.path.inspect}, because it's revision pointer change isn't committed.</h3>"
          when new_module && ! new_module.cloned?
            puts "<h3>Cloning new submodule #{new_module.path.inspect}</h3>"
            puts "<pre>#{h new_module.init}\n#{h new_module.update}</pre>"
          when old_module && ! new_module
            puts "<h3>Cacheing submodule #{old_module.path.inspect} to #{old_module.git.root_relative_path_for(old_module.abs_cache_path).inspect}</h3>"
            old_module.cache
          when new_module && new_module.cached?
            puts "<h3>Restoring submodule #{new_module.path.inspect} from cache.</h3>"
            puts "Restoration failed: a folder is in the way." unless new_module.restore
            update_submodule(new_module) if new_module.modified?
          when ( ! old_module ) || ( ! old_module.modified? ) && new_module.modified?
            puts "<h3>Updating submodule #{new_module.path.inspect}</h3>"
            update_submodule(new_module)
          end
          flush
        end
      end
    end
    
    def get_submodule_hash
      git.submodule.all.inject({}) { |h, sm| h[sm.path] = sm; h }
    end
    
    def update_submodule(submodule)
      puts "<pre>#{h submodule.update}</pre>"
    end
  end
  
  def render_submodule_header(submodule)
    puts "<h3>... in submodule ‘#{link_to_mate(submodule.path, submodule.git.path)}’</h3>"
  end
end
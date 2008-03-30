require 'erb'

class ERBStdout < ERB
  def set_eoutvar(compiler, eoutvar = 'STDOUT')
    compiler.put_cmd = "#{eoutvar} << "
    compiler.insert_cmd = "#{eoutvar} << " if compiler.respond_to?(:insert_cmd)
    compiler.pre_cmd = "#{eoutvar}.flush"
    compiler.post_cmd = "#{eoutvar}.flush; ''"
  end
  
  def run(b=TOPLEVEL_BINDING)
    self.result(b)
  end
end


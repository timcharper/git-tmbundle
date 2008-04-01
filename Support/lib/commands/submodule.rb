class SCM::Git::Submodule < SCM::Git::SubmoduleBase
  def init_and_update
    output = @base.command("submodule", "init")
    output << @base.command("submodule", "update")
    output
  end
  
  def list
    @base.command("submodule").split("\n").map do |line|
      next unless line.match(/\s*([a-f0-9]+) (\w+) \((\w+)\)/)
      {
        :revision => $1,
        :name => $2,
        :tag => ($3 == "undefined" ? nil : $3)
      }
    end
  end
end
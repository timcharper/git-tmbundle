class SCM::Git::Log
  include SCM::Git::CommonCommands
  
  def initialize
  end
  
  def run
    git   = SCM::Git.new
    paths = paths(:fallback => :current_file, :unique => true)
    base  = nca(paths)

    Dir.chdir(base)

    paths.each do |path|

      puts "<h1>Log for ‘#{htmlize(shorten(path, base))}’</h1>"
      colors = %w[ white lightsteelblue ]

      file = if path == base then '.' else shorten(path, base) end
      output = log(file)
      output.scan(/^commit (.+)$\n((?:\w+: .*\n)*)((?m:.*?))(?=^commit|\z)/) do |e|
          commit, msg = $1, $3
          headers = $2.scan(/(\w+):\s+(.+)/)

          puts "<div style='background: #{colors[0]};'>"
          puts "<h2>Commit #{htmlize commit.sub(/^(.{8})(.{10}.*)/, '\1…')}</h2>"
          puts headers.map { |e| "<dt>#{htmlize e[0]}</dt>\n<dd>#{htmlize e[1]}</dd>\n" }
          puts "<p>#{htmlize msg.gsub(/\A\n+|\n+\z/, '').gsub(/^    /, '')}</p>"
          puts "</div>"

          colors = [colors[1], colors[0]]
      end
    end
  end
  
  def log(file_or_directory)
    command("log", file_or_directory)
  end
end
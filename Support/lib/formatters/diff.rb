class Formatters::Diff
  
  def initialize(base, &block)
    @base = base
    puts <<-EOF
    <html>
    <head>
      <title>Uncomitted changes</title>
    <style>
      h2 { font-size:20px; padding-bottom:20px; }
      code .diff_cmd { font-color: #aaa; padding: 5px 0px; border-color: black; border-style: dashed; border-width: 1px 0px 0px 0px; margin-top: 10px; }
      code .addition { background-color: #cfc; }
      code .deletion { background-color: #fcc; }
      code .info {background-color: #ccc;  }
    </style>
    </head>
    <body>
    EOF
    yield self
    
    puts <<-EOF
    </body>
    </html>
    EOF
  end
  
  def header(text)
    puts "<h2>#{text}</h2>"
  end
  
  def content(diff_result)
    puts '<code>'
    diff_result.split("\n").each do |line|
      css_class = case line
      when /^(diff |index |@@|\+\+\+|\-\-\-)/
        "info"
      when /^\+/
        "addition"
      when /^\-/
        "deletion"
      when /^diff /
        "diff_cmd"
      else
        ""
      end
      puts "<div class='#{css_class}'>#{htmlize(line)}</div>"
    end
    
    puts '</code>'
  end

end
class Formatters::Annotate
  include Formatters::FormatterHelpers
  
  def initialize(base = nil, options = {}, &block)
    @base = base || ENV["TM_PROJECT_DIRECTORY"]
    @header = options[:header] || "Annotate / Blame"
    puts <<-EOF
    <html>
    <head>
      <title>#{@header}</title>
      <link type="text/css" rel="stylesheet" media="screen" href="#{resource_url('style.css')}"/>
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
  
  def make_non_breaking(output)
    htmlize(output.to_s.strip).gsub(" ", "&nbsp;")
  end
  
  def content(annotations)
    # puts annotations.inspect
    puts '<code>'
    puts <<-EOF
      <table class='codediff inline'>
        <thead>
          <tr>
            <td class='line-numbers'>revision</td>
            <td class='line-numbers'>author</td>
            <td class='line-numbers'>date</td>
            <td class='line-numbers'>line</td>
            <td/>
          </tr>
        </thead>
        <tbody>
    EOF
    annotations.each do |annotation|
      col_class = (ENV["TM_LINE_NUMBER"].to_i == annotation[:ln].to_i) ? "selected" : ""
      puts <<-EOF
        <tr>
          <td class="line-numbers">#{make_non_breaking annotation[:rev]}</td>
          <td class="line-numbers">#{make_non_breaking annotation[:author]}</td>
          <td class="line-numbers">#{make_non_breaking annotation[:date].to_friendly}</td>
          <td class="line-numbers">#{make_non_breaking annotation[:ln]}</td>
          <td class="code #{col_class}">#{htmlize(annotation[:text])}</td>
        </tr>
      EOF
    end
      
    puts <<-EOF
        </tbody>
      </table>
    EOF
    puts '</code>'
  end

end


module FriendlyTime
  def to_friendly(time=true)
    time=false if Date==self.class
    
    ret_val = if time
      strftime "%b %d, %Y %I:%M %p" + (time=="zone"? " %Z" : "")
    else
      strftime "%b %d, %Y"
    end
    
    ret_val.gsub(" 0", " ")
  end
end

class Time
  include FriendlyTime
end

class Date
  include FriendlyTime
end

class DateTime
  include FriendlyTime
end


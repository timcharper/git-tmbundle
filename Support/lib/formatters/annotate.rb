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
  
  def select_options_tag(select_options = [])
    output = ""
    
    select_options.each do |name, val|
      output << "<option value='#{val}'>#{htmlize(name)}</option>"
    end
    
    output
  end
  
  def select_box(name, select_options = [], options = {})
    options[:name] ||= name
    options[:id] ||= name
    # puts select_options.inspect
    puts <<-EOF
      Previous revisions
      <select name='#{options[:name]}' id='#{options[:id]} onchange="#{options[:onchange]}"'>
        #{select_options_tag(select_options)}
      </select>
    EOF
  end
  
  def content(annotations, log_entries = nil)
    if log_entries
      puts select_box(
        "rev",
        [["current", ""]] + log_entries.map{|le| ["#{short_rev(le[:rev])} - #{le[:author]} - #{le[:date].to_friendly}", le[:rev]] },
        :onchange => "alert('hi');"
      )
    end
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
    last_formatted_line = {}
    
    annotations.each do |annotation|
      col_class = []
      col_class << "selected" if ENV["TM_LINE_NUMBER"].to_i == annotation[:ln].to_i
      col_class << "ins" if annotation[:rev] == "-"      
      col_class = col_class * " "
      formatted_line = {:rev => annotation[:rev], :author => annotation[:author], :date => annotation[:date].to_friendly, :ln => annotation[:ln]}
      display = formatted_line.dup
      [:rev, :author, :date, :ln].each do |k|
        display[k] = "" if display[k]==last_formatted_line[k]
      end
      
      puts <<-EOF
        <tr>
          <td class="line-numbers">#{make_non_breaking annotation[:rev]}</td>
          <td class="line-numbers">#{make_non_breaking annotation[:author]}</td>
          <td class="line-numbers">#{make_non_breaking annotation[:date].to_friendly}</td>
          <td class="line-numbers">#{make_non_breaking annotation[:ln]}</td>
          <td class="code #{col_class}">#{htmlize(annotation[:text])}</td>
        </tr>
      EOF
      last_formatted_line = formatted_line
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


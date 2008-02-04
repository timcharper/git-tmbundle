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
  
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round
    
    case distance_in_minutes
      when 0..1
        return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
        case distance_in_seconds
          when 0..4   then 'less than 5 seconds'
          when 5..9   then 'less than 10 seconds'
          when 10..19 then 'less than 20 seconds'
          when 20..39 then 'half a minute'
          when 40..59 then 'less than a minute'
          else             '1 minute'
        end
      
      when 2..44           then "#{distance_in_minutes} minutes"
      when 45..89          then 'about 1 hour'
      when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
      when 1440..2879      then '1 day'
      when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
      when 43200..86399    then 'about 1 month'
      when 86400..525599   then "#{(distance_in_minutes / 43200).round} months"
      when 525600..1051199 then 'about 1 year'
      else                      "over #{(distance_in_minutes / 525600).round} years"
    end
  end
  
  def friendly_date(date)
    return date if date.is_a?(String)
    distance_of_time_in_words(Time.now, date)
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
      col_class << "ins" if annotation[:rev] == "-none-"      
      col_class = col_class * " "
      formatted_line = {
        :rev => annotation[:rev], 
        :author => annotation[:author], 
        :date => friendly_date(annotation[:date]), 
        :ln => annotation[:ln], 
        :text => annotation[:text]
      }
      display = formatted_line.dup
      
      [:rev, :author, :date].each { |k| display[k] = "…" } if display[:rev]==last_formatted_line[:rev]
      puts <<-EOF
        <tr>
          <td class="line-numbers">#{make_non_breaking display[:rev]}</td>
          <td class="line-numbers">#{make_non_breaking display[:author]}</td>
          <td class="line-numbers">#{make_non_breaking display[:date]}</td>
          <td class="line-numbers">#{make_non_breaking display[:ln]}</td>
          <td class="code #{col_class}">#{htmlize(display[:text])}</td>
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


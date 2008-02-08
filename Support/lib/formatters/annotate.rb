class Formatters
  class Annotate
    include Formatters::FormatterHelpers
  
    def initialize(options = {}, &block)
      @base = options[:base] || ENV["TM_PROJECT_DIRECTORY"]
      @header = options[:header] || "Annotate / Blame"
      @log_entries = options[:log_entries]
      @selected_revision = options[:selected_revision]
      @as_partial = options[:as_partial]
    
      layout {yield self} if block_given?
    end
  
    def layout(&block)
      render("layout", &block)
    end
  
    def header(text)
      @header = text
      ""
      # puts "<h2>#{text}</h2>"
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
  
    def relative_date(date)
      return date if date.is_a?(String)
      distance_of_time_in_words(Time.now, date)
    end
  
    def navigate_box
      formatted_options = [["current", ""]] + @log_entries.map{|le| ["#{short_rev(le[:rev])} - #{relative_date(le[:date])} - #{le[:author]} - #{le[:msg].split("\n").first}", short_rev(le[:rev])] }
      render("navigate_box", :locals => {:formatted_options => formatted_options, :selected_revision => @selected_revision, } )
    end
  
    def content(annotations)
      # puts annotations.inspect
      last_formatted_line = {}
    
      formatted_annotations = annotations.map do |annotation|
        col_class = []
        col_class << "selected" if ENV["TM_LINE_NUMBER"].to_i == annotation[:ln].to_i
        col_class << "ins" if annotation[:rev] == "-current-" || annotation[:rev] == @selected_revision
        col_class = col_class * " "
        formatted_line = {
          :rev => annotation[:rev], 
          :author => annotation[:author], 
          :date => relative_date(annotation[:date]), 
          :ln => annotation[:ln], 
          :text => annotation[:text]
        }
        display = formatted_line.dup
      
        [:rev, :author, :date].each { |k| display[k] = "…" } if display[:rev]==last_formatted_line[:rev]
      
        friendly_date = annotation[:date].is_a?(Time) ? annotation[:date].to_friendly : annotation[:date]
      
        display[:rev_tooltip] = <<EOF
  Revision: #{annotation[:rev]}
  Date: #{friendly_date} (#{display[:date]})
  Author: #{annotation[:author]}
EOF
        display[:line_col_class] = col_class
        
        last_formatted_line = formatted_line
        display
      end
      
      render("content", :locals => {:formatted_annotations => formatted_annotations})
    end
  
    def js_select_current_revision
      <<-EOF
      EOF
    end
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


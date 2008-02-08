require File.dirname(__FILE__) + '/../date_helpers.rb'
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
    
    include DateHelpers
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


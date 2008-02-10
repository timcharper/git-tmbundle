require File.dirname(__FILE__) + '/../date_helpers.rb'
class Formatters
  class Push < Formatters
    def initialize(*args)
      @header = "Push"
      super
    end
    
    def header(text)
      puts "<h2>#{text}</h2>"
    end
    
    def progress_start(state, count)
      puts("<div>#{state} #{count} objects.  <span id='#{state}_progress'>0% 0 / #{count}</span></div>")
    end
    
    def progress(state, percentage, index, count)
      puts <<-EOF
      <script language='JavaScript'>
        $('#{state}_progress').update('#{percentage}% #{index} / #{count}')
      </script>
      EOF
      
      flush 
    end
    
    def progress_end(state, count)
      puts <<-EOF
      <script language='JavaScript'>
        $('#{state}_progress').update('Done')
      </script>
      EOF
      flush
    end
  end
end
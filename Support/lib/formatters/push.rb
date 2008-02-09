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
      puts("#{state} #{count} objects.  <div id='#{state}_progress'>0% 0 / #{count}</div>")
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
    
    def diffs(branch_revisions)
      diff = SCM::Git::Diff.new
      diff_f = Formatters::Diff.new
      branch_revisions.each do |branch, revisions|
        diff_f.header("Diff on changes pushed")
        diff_f.sub_header("Branch '#{branch}': #{short_rev(revisions.first)}..#{short_rev(revisions.last)}")
        diff_f.content diff.diff_revisions(".", revisions.first, revisions.last)
      end
    end
  end
end
class Formatters::Diff < Formatters
  
  def initialize(options = {}, &block)
    @base = ENV["TM_PROJECT_DIRECTORY"]
    @rev = options[:rev]
    @header = options[:header] || "Uncomitted changes"
    
    super
  end
    
  def open_in_tm_link
    puts <<-EOF
      <a href='txmt://open?url=file://#{e_url '/tmp/output.diff'}'>Open diff in TextMate</a>
    EOF
  end
  
  def header(text)
    puts "<h2>#{text}</h2>"
  end
  
  def content(diff_results)
    puts '<code>'
    diff_results.each do |diff_result|
      files = [:left, :right].map do |lr|
        filepath = diff_result[lr][:filepath]
        start_line_right = diff_result[:right][:ln_start]
        
        if filepath
          link = 
            if (@rev.nil? || @rev.empty?) 
              "txmt://open?url=file://#{e_url File.join(@base, filepath)}&line=#{start_line_right}"
            else 
              %Q{javascript:gateway_command("show.rb", ["#{e_js filepath}", "#{@rev}", "#{start_line_right}"] );}
            end
            filepath ? %Q{<a href='#{link}'>#{htmlize filepath}</a>} : "(none)"
        else
          "(none)"
        end
      end
      puts <<-EOF
      <h4>#{files.uniq * ' --&gt; '}</h4>
      <table class='codediff inline'>
        <thead>
          <tr>
            <td class='line-numbers'>left</td>
            <td class='line-numbers'>right</td>
            <td/>
          </tr>
        </thead>
        <tbody>
EOF
      diff_result[:lines].each do |line|
        line_num_class, row_class = case line[:type]
        when :deletion then ["", "del"]
        when :insertion then ["", "ins"]
        when :eof then ["line-num-eof", "eof"]
        when :cut then ["line-num-cut", "cut-line"]
        else
          ["", "unchanged"]
        end
        puts <<-EOF
          <tr>
            <td class="line-numbers #{line_num_class}">#{line[:ln_left]}</td>
            <td class="line-numbers #{line_num_class}">#{line[:ln_right]}</td>
            <td class="code #{row_class}">#{htmlize(line[:text])}</td></tr>
        EOF
      end
      
      puts <<-EOF
        </tbody>
      </table>
      EOF
    end
    puts '</code>'
  end

end
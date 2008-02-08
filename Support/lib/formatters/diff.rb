class Formatters::Diff
  include Formatters::FormatterHelpers
  
  def initialize(base = nil, options = {}, &block)
    @base = ENV["TM_PROJECT_DIRECTORY"]
    @header = options[:header] || "Uncomitted changes"
    puts <<-EOF
    <html>
    <head>
      <title>#{@header}</title>
      <link type="text/css" rel="stylesheet" media="screen" href="#{resource_url('style.css')}"/>
    </head>
    <body>
      <a href='txmt://open?url=file://#{e_url '/tmp/output.diff'}'>Open in TextMate</a>
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
  
  def content(diff_results)
    puts '<code>'
    diff_results.each do |diff_result|
      files = [:left, :right].map do |lr|
        filepath = diff_result[lr][:filepath]
        start_line_right = diff_result[:right][:ln_start]
        filepath ? "<a href='txmt://open?url=file://#{e_url File.join(@base, filepath)}&line=#{start_line_right}'>#{htmlize filepath}</a>" : " - none - "
      end
      puts <<-EOF
      <h4>#{files.uniq * ' --- '}</h4>
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
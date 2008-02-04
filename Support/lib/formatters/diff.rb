class Formatters::Diff
  include Formatters::FormatterHelpers
  
  def initialize(base, &block)
    @base = base
    
    puts <<-EOF
    <html>
    <head>
      <title>Uncomitted changes</title>
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
  
  def content(diff_results)
    puts '<code>'
    diff_results.each do |diff_result|
      files = [:left, :right].map{|lr| diff_result[lr][:filepath] || " - none - "}
      puts <<-EOF
      <h4>#{files.uniq * ' / '}</h4>
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
        row_class = case line[:type]
        when :deletion then "del"
        when :insertion then "ins"
        else
          "unchanged"
        end
        puts <<-EOF
          <tr>
            <td class="line-numbers">#{line[:ln_left]}</td>
            <td class="line-numbers">#{line[:ln_right]}</td>
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
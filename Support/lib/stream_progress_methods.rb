
module StreamProgressMethods
  extend self
  
  def each_line_from_stream(stream, &block)
    line = ""
    f = File.open("/tmp/output", "wb")
    stream.each_byte do |char|
      f.putc(char)
      char = [char].pack('c')
      line << char
      next unless char=="\n" || char=="\r"
      yield line
      line = ""
    end
    yield line
    stream
  end
  protected  

    def process_with_progress(stream, options = {}, &block)
      options[:start_regexp] ||= /(?-:remote: )?([a-z]+) ([0-9]+) objects/i
      options[:progress_regexp] ||= /(?-:(?-:remote: )?([a-z]+) objects: +)?([0-9]+)% \(([0-9]+)\/([0-9]+)\)/i
      callbacks = options[:callbacks]
      state = nil
      each_line_from_stream(stream) do |line|
        case line
        when options[:start_regexp]
          state = $1
          callbacks[:start] && callbacks[:start].call(state, $2.to_i)
          percentage, index, count = 0, 0, $2.to_i
        when options[:progress_regexp]
          percentage, index, count = $2.to_i, $3.to_i, $4.to_i
          if $1 && state != $1 && percentage != 100
            state = $1
            callbacks[:start] && callbacks[:start].call(state, count)
          end
        else
          yield line
        end
        
        if state && index
          callbacks[:progress] && callbacks[:progress].call(state, percentage, index, count)
          if percentage == 100
            callbacks[:end] && callbacks[:end].call(state, count)
            state = nil 
          end
        end
      end
    end

    def get_rev_range(input)
      revs = input.split("..").compact
      revs = ["#{revs[0]}^", revs[0]] if revs.length == 1
      revs
    end
end


module EnhancedStream
  def each_line_from_stream(&block)
    StreamProgressMethods.each_line_from_stream(self, &block)
  end
  
  def pipe_to(dest)
    each_line_from_stream do |line|
      dest << line
      dest.flush
    end
  end
end

IO.send :include, EnhancedStream
StringIO.send :include, EnhancedStream

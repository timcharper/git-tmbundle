require ENV['TM_SUPPORT_PATH'] + '/lib/ui.rb'

class << TextMate::UI
  def request_item_with_force_pick(options = {}, &block)
    if options[:force_pick]
      options[:items] << "" if options[:items].length == 1
    end
    
    request_item_without_force_pick(options, &block)
  end
  alias_method_chain :request_item, :force_pick
  
  def request_directory(title = "Select a directory", options = {})
    options[:initial_directory] ||= ENV['TM_PROJECT_DIRECTORY'] || ENV['TM_FILEPATH']
    result = `CocoaDialog fileselect --select-only-directories --with-directory "#{options[:initial_directory]}" --title "#{title}"`
    result.empty? ? nil : result.strip
  end
end
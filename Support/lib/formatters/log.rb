require File.dirname(__FILE__) + '/../date_helpers.rb'
class Formatters::Log < Formatters
  include DateHelpers
  def content(log_entries, branch = nil)
    diff_formatter = Formatters::Diff.new
    branch ||= Git.new.current_branch
    log_entries.each do |log_entry|
      render("log_entry", :locals => {:log_entry => log_entry, :diff_formatter => diff_formatter, :branch => branch})
    end
  end
end
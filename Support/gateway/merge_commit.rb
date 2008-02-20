require File.dirname(__FILE__) + '/../lib/git.rb'

begin
  message = ARGV[0]
  status = Git::Status.new
  commit = Git::Commit.new
  f = Formatters::Commit.new
  f.layout do 
    statuses = status.status(status.git_base)
    files = statuses.map { |status_options| (status_options[:status][:short] == "?") ? nil : commit.make_local_path(status_options[:path]) }.compact

    commit.auto_add_rm(files)
    res = commit.commit(message, [])
    f.output_commit_result(res)
  end
rescue => e
  puts e.to_s
end
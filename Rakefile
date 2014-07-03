load 'bootstrap.rb'

task :setup do
  Bundler.setup :default, :development
  
  require 'pry'
end

task console: :setup do
  binding.pry
end

task simple_run: :setup do
  Bundler.setup :default

  str = ENV["URL"]
  raise ArgumentError, "URL not provided as arg" if str.nil? || str.empty?

  out = ENV["FILE"]
  raise ArgumentError, "FILE not provided as arg" if out.nil? || out.empty?
  SimpleCrawler::Tasks::SingleRun.run str, out
end

task run: :setup do
  Bundler.setup :default

  str = ENV["URL"]
  raise ArgumentError, "URL not provided as arg" if str.nil? || str.empty?

  out = ENV["FILE"]
  raise ArgumentError, "FILE not provided as arg" if out.nil? || out.empty?

  require 'logger'

  SimpleCrawler.logger.level = Logger::INFO

  s_thread = SimpleCrawler::Tasks::MultiWorker.run str, out
  puts
  until s_thread.main_thread.status == nil || s_thread.main_thread.status == false
    print "\rActive workers: #{s_thread.num_active_workers} Results: #{s_thread.session.results_store.contents.length}"
    sleep 0.001
  end
  puts
end
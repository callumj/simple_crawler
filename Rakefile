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
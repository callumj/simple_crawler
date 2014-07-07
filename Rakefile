load 'bootstrap.rb'

task :setup do
  Bundler.setup :default, :development
  
  require 'pry'
end

task console: :setup do
  binding.pry
end

task server: :setup do
  Bundler.setup :default

  str = ENV["URL"]
  raise ArgumentError, "URL not provided as arg" if str.nil? || str.empty?

  out = ENV["OUTPUT"]
  raise ArgumentError, "OUTPUT not provided as arg" if out.nil? || out.empty?

  listen = ENV["LISTEN"]
  server = SimpleCrawler::Tasks::ServerOnly.run str, out, listen

  trap("SIGINT") { server.shutdown! }

  STDERR.puts "Listening: #{server.host}:#{server.port}"

  max_length = 0
  while server.active
    s = "\rActive connections: #{server.active_connections.length} Results: #{server.crawl_session.results_store.contents.length} Popped off: #{server.awaiting_uris.length}"
    max_length = s.length if s.length > max_length
    STDERR.print s
    sleep 0.001
    STDERR.print max_length.times.map { " " }.join
  end
  puts
end

task simple_run: :setup do
  Bundler.setup :default

  str = ENV["URL"]
  raise ArgumentError, "URL not provided as arg" if str.nil? || str.empty?

  out = ENV["OUTPUT"]
  raise ArgumentError, "OUTPUT not provided as arg" if out.nil? || out.empty?
  SimpleCrawler::Tasks::SingleRun.run str, out
end

task run: :setup do
  Bundler.setup :default

  require 'logger'

  SimpleCrawler.logger.level = Logger::INFO

  res_store = false

  s_thread = nil
  if ENV["SERVER"]
    split = ENV["SERVER"].split ":"
    host = split.length >= 2 ? split[0] : nil
    port = !split.last.nil? && split.last.to_i
    s_thread = SimpleCrawler::Tasks::MultiWorker.client host, port
  else
    str = ENV["URL"]
    raise ArgumentError, "URL not provided as arg" if str.nil? || str.empty?

    out = ENV["OUTPUT"]
    raise ArgumentError, "OUTPUT not provided as arg" if out.nil? || out.empty?
    s_thread = SimpleCrawler::Tasks::MultiWorker.run str, out
    res_store = true
  end

  trap("SIGINT") { s_thread.shutdown! }

  until s_thread.main_thread.status == nil || s_thread.main_thread.status == false
    str = "\rActive workers: #{s_thread.num_active_workers}"
    str << " Results: #{s_thread.session.results_store.contents.length}" if res_store

    STDERR.print str
    sleep 0.001
    STDERR.print 100.times.map { " " }.join
  end
  puts
end
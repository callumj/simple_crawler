require 'spec_helper'

describe SimpleCrawler::Scrapers::HTML do

  def create(file)
    path = File.join(SPEC_ROOT, "files", "#{file}.html")
    src = File.open(path, "r") { |f| f.read }
    described_class.new SimpleCrawler::Models::DownloadResponse.new(src)
  end

  it "should be able to understand callumj.com" do
    inst = create "callumj.com"
    expect(inst.assets).to eq([
      ["http://fonts.googleapis.com/css?family=Source+Sans+Pro:400", ""],
      ["style/style.css", ""],
      ["http://metrix.callumj.com/metric/increment?key=callumj&subkey=index", ""]
    ])

    expect(inst.links).to eq([
      ["#about", "About"],
      ["https://github.com/callumj", "GitHub"],
      ["https://twitter.com/callumj", "Twitter"],
      ["resume.html", "Resume"],
      ["mailto:contact@callumj.com", "Email"],
      ["http://webcache.googleusercontent.com/search?q=cache:_vc8w4-Hn4UJ:thenextweb.com/apps/2013/09/24/discovr-revamp-ios/+&cd=1&hl=en&ct=clnk&gl=au",
      "Discovr"],
      ["http://webcache.googleusercontent.com/search?q=cache%3AuLzIWzXvo48J%3Athenextweb.com%2Fapps%2F2010%2F07%2F09%2Fcant-wait-for-facebooks-place-recommendations-rummble-has-an-answer-now%2F%20&cd=1&hl=en&ct=clnk&gl=au#!CC5pe",
      "Rummble"],
      ["http://www.slideshare.net/callumj/railsgirls-28271742", "RailsGirls"],
      ["https://soundcloud.com/callumj", "music."],
      ["posts/weave_docker_buildbox.html", "Docker continuous deployment with weave and Buildbox"],
      ["http://callummjones.tumblr.com/post/79866627645/rails-ios-dev", "What I've learnt about iOS development as a Rails developer"],
      ["https://itunes.apple.com/app/extended/id836630098", "Extended"],
      ["http://callummjones.tumblr.com/post/60421062721/why-the-nbn-needs-go-the-full-way", "Why the NBN needs go the full way."],
      ["http://callummjones.tumblr.com/post/49775678492/the-pebble-watch-is-an-exciting-sneak-peak", "The Pebble watch is an exciting sneak peak"],
      ["https://github.com/callumj/weave", "weave"],
      ["https://itunes.apple.com/us/app/extended/id836630098", "Extended"],
      ["https://github.com/callumj/media_baron", "media_baron"],
      ["https://github.com/callumj/RickshawSubGraph", "RickshawSubGraph"],
      ["https://github.com/callumj/SlimMigration", "SlimMigration"],
      ["https://github.com/callumj/Tedious", "Tedious"],
      ["https://github.com/callumj/metrix", "metrix"],
      ["https://github.com/callumj/DockerConf", "DockerConf"],
      ["https://github.com/callumj/MyAnsible", "MyAnsible"],
      ["https://gist.github.com/callumj/9482396", "NUnit database helper"],
      ["https://gist.github.com/callumj/6946282", "MySQL TCPDUMP"],
      ["https://gist.github.com/callumj/9478144", "Ruby app Dockerfile bootstrap"],
      ["https://github.com/callumj/GovHackWeb", "GruntJS example frontend application"]
    ])
  end

end
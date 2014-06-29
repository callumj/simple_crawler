require 'spec_helper'

describe SimpleCrawler::Downloader do

  def perform(url)
    described_class.source_for url
  end

  def system_curl(url)
    `curl -s #{url}`
  end

  it "should handle weird encoding endpoints" do
    res = perform "http://datacom.com.au"
    expect(res.status).to eq(200)

    system = system_curl("http://datacom.com.au")

    system.gsub! /id="__VIEWSTATE"\s+value="[^"]+"/, "viewstate"
    res.source.gsub! /id="__VIEWSTATE"\s+value="[^"]+"/, "viewstate"
    expect(res.source).to eq(system)
  end

  it "should follow redirects" do
    res = perform "http://bit.ly/1pC8oW9"
    expect(res.status).to eq(200)
    expect(res.final_uri).to eq(URI("http://callumj.com"))

    system = system_curl("http://callumj.com")
    expect(res.source).to eq(system)
  end

  it "should support HTTPS" do
    res = perform "https://sslcheck.globalsign.com/en_US"
    expect(res.status).to eq(200)

    system = system_curl("https://sslcheck.globalsign.com/en_US")
    expect(res.source).to eq(system)
  end

  it "should support 404" do
    res = perform "http://callumj.com/thisdoesnotexist"
    expect(res.status).to eq(404)

    expect(res.source).to include("404 Not Found", "nginx/1.4.6 (Ubuntu)")
    expect(res.headers["Server"]).to eq("nginx/1.4.6 (Ubuntu)")
  end

end

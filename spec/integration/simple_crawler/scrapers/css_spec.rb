require 'spec_helper'

describe SimpleCrawler::Scrapers::CSS do

  def create(file)
    path = File.join(SPEC_ROOT, "files", "#{file}.css")
    src = File.open(path, "r") { |f| f.read }
    described_class.new SimpleCrawler::Models::DownloadResponse.new(src)
  end

  it "should be able to understand callumj.com" do
    inst = create "soundcloud"
    expect(inst.assets).to match_array([["https://a-v2.sndcdn.com/assets/images/back-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/mobile-apps/google_play_badge-26373985.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/mobile-apps/appstore_badge-26373985.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/mobile-apps/google_play_badge@2x-26373985.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/mobile-apps/appstore_badge@2x-26373985.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/glass-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/sounds-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/sets-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/people-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/groups-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/music-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/audio-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/nav-items/highlight-38b02b00.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/compact/remove-897c3346.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/compact/remove@2x-897c3346.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/alert-9a8180f4.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/alert@2x-9a8180f4.png", "image"], 
      ["https://a-v2.sndcdn.com/assets/images/copyright-38b02b00.png", "image"], 
      ["../fonts/fontawesome-webfont.eot?v=4.0.3", "font"]])

    expect(inst.links).to be_empty
  end

end
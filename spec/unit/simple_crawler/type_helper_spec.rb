require 'spec_helper'

describe SimpleCrawler::TypeHelper do

  def uri(url)
    Addressable::URI.parse url
  end

  describe ".can_be_downloaded?" do

    it "should be true if the extension cannot be located" do
      expect(described_class).to be_can_be_downloaded(uri("http://google.com").path)
    end

    it "should be true if it doesn't know what to do with the extension" do
      expect(MIME::Types).to receive(:type_for).with(".html").and_return([])
      expect(described_class).to be_can_be_downloaded(uri("http://google.com/index.html?ssss=okay").path)
    end

    it "should be false if one matched mime type is invalid" do
      described_class::BANNED_DOWNLOAD_MEDIA_TYPES.each do |m|
        set = [
          double(:mime_type).tap { |d| expect(d).to receive(:media_type).and_return("text") },
          double(:mime_type).tap { |d| expect(d).to receive(:media_type).and_return(m) }
        ]
        expect(MIME::Types).to receive(:type_for).with(".html").and_return(set)
        expect(described_class).to_not be_can_be_downloaded(uri("http://google.com/index.html?ssss=okay").path)
      end
    end

  end

  describe ".type_from_name" do

    it "should be nil without anything" do
      expect(described_class.type_from_name(nil)).to be_nil
    end

    it "should detect a stylesheet" do
      expect(described_class.type_from_name("fff.css")).to eq "stylesheet"
    end

    it "should detect fonts" do
      %w(woff ttf otf eot).each do |ext|
        expect(described_class.type_from_name("ffff.#{ext}")).to eq("font"), "#{ext} should be a font"
      end
    end

    it "should detect images" do
      %w(png gif bmp tif tiff xbm jpg jpeg).each do |ext|
        expect(described_class.type_from_name("ffff.#{ext}")).to eq("image"), "#{ext} should be a font"
      end
    end

    it "should detect a JS" do
      expect(described_class.type_from_name("fff.js")).to eq "javascript"
    end

  end

end
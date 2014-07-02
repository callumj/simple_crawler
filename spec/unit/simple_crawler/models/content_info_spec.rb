require 'spec_helper'

describe SimpleCrawler::Models::ContentInfo do

  let(:uri) { Addressable::URI.parse "http://callumj.com/index.html" }

  context 'initializing' do

    it "should allow for initializing with just the URI" do
      inst = described_class.new uri
      expect(inst.assets).to be_empty
      expect(inst.links).to be_empty
    end

    it "should allow for initializing with assets" do
      assets = double(:assets)
      ret = double(:ret)
      expect(SimpleCrawler::Utils).to receive(:set_from_possible_array).with(assets, SimpleCrawler::Models::Asset).and_return(ret)
      expect(SimpleCrawler::Utils).to receive(:set_from_possible_array).with(nil, SimpleCrawler::Models::Link).and_call_original

      inst = described_class.new uri, assets
      expect(inst.instance_variable_get(:@assets)).to eq ret
    end

    it "should allow for initializing with links" do
      links = double(:links)
      ret = double(:ret)
      expect(SimpleCrawler::Utils).to receive(:set_from_possible_array).with(links, SimpleCrawler::Models::Link).and_return(ret)
      expect(SimpleCrawler::Utils).to receive(:set_from_possible_array).with(nil, SimpleCrawler::Models::Asset).and_call_original

      inst = described_class.new uri, nil, links
      expect(inst.instance_variable_get(:@links)).to eq ret
    end

  end

  describe "manipulating assets" do

    subject { described_class.new uri }

    it "should provide access" do
      expect(subject.assets).to be_a(Set)
    end

    it "should allow be to add assets via add_assets" do
      uri = Addressable::URI.parse("http://gle.com/asset.png")
      asset = SimpleCrawler::Models::Asset.new uri, "img"
      subject.add_assets asset
      expect(subject.assets).to include asset
    end

    it "should allow more than one asset" do
      uri = Addressable::URI.parse("http://gle.com/asset.png")
      asset = SimpleCrawler::Models::Asset.new uri, "img"

      uri2 = Addressable::URI.parse("http://gle.com/asset.gif")
      asset2 = SimpleCrawler::Models::Asset.new uri2, "img"

      subject.add_assets [asset, asset2]
      expect(subject.assets).to include asset, asset2
    end

    it "should not allow dupes" do
      uri = Addressable::URI.parse("http://gle.com/asset.png")
      asset = SimpleCrawler::Models::Asset.new uri, "img"

      uri2 = Addressable::URI.parse("http://gle.com/asset.gif")
      asset2 = SimpleCrawler::Models::Asset.new uri2, "img"

      uri3 = Addressable::URI.parse("http://gle.com/asset.gif")
      asset3 = SimpleCrawler::Models::Asset.new uri3, "img"

      subject.add_assets [asset, asset2]
      expect(subject.assets).to include asset, asset2

      expect do
        subject.add_assets asset3
      end.to_not change { subject.assets }
    end

  end

describe "manipulating links" do

    subject { described_class.new uri }

    it "should provide access" do
      expect(subject.links).to be_a(Set)
    end

    it "should allow be to add links via add_assets" do
      uri = Addressable::URI.parse("http://gle.com/index.html")
      link = SimpleCrawler::Models::Link.new uri

      subject.add_links link
      expect(subject.links).to include link
    end

    it "should allow more than one link" do
      uri = Addressable::URI.parse("http://gle.com/help")
      link = SimpleCrawler::Models::Link.new uri

      uri2 = Addressable::URI.parse("http://gle.com/account")
      link2 = SimpleCrawler::Models::Link.new uri2

      subject.add_links [link, link2]
      expect(subject.links).to include link, link2
    end

    it "should not allow dupes" do
      uri = Addressable::URI.parse("http://gle.com/help")
      link = SimpleCrawler::Models::Link.new uri

      uri2 = Addressable::URI.parse("http://gle.com/account")
      link2 = SimpleCrawler::Models::Link.new uri2

      uri3 = Addressable::URI.parse(uri2.to_s)
      link3 = SimpleCrawler::Models::Link.new uri3

      subject.add_links [link, link2]
      expect(subject.links).to include link, link2

      expect do
        subject.add_links link3
      end.to_not change { subject.links }
    end

  end

end
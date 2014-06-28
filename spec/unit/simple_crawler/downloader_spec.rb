require 'spec_helper'

describe SimpleCrawler::Downloader do

  describe ".source_for" do

    let(:inst) { double(described_class.name.to_sym) }

    it "should initialize an instance with the provided url and call #obtain_source" do
      url = "http://altavista.com"
      expect(described_class).to receive(:new).with(url).and_return(inst)
      expect(inst).to receive(:obtain_source).and_return(:ret)

      expect(described_class.source_for(url)).to eq(:ret)
    end

  end

  describe "#obtain_source" do
    subject { described_class.new("http://ask.com/req/a/b?query=true&fun=ok#loc1") }
  end

end
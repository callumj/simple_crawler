require 'spec_helper'

describe SimpleCrawler::Scrapers::HTML do

  let(:download_response) do
    SimpleCrawler::Models::DownloadResponse.new("SOURCE_CODE")
  end

  let(:nokogiri_doc) { double(:nokogiri_doc) }

  before :each do
    expect(Nokogiri).to receive(:HTML).with("SOURCE_CODE").and_return(nokogiri_doc)
  end

  subject { described_class.new download_response }

  describe "#links" do

    let(:nd1) do
      double(:nd1).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return(nil)
        expect(n).to receive(:[]).with("href").and_return("/a_href")
        expect(n).to receive(:text).and_return("A")
      end
    end
    let(:nd2) do
      double(:nd2).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return(nil)
        expect(n).to receive(:[]).with("href").and_return("http://google.com/a_href")
        expect(n).to receive(:text).and_return("B")
      end
    end
    let(:nd3) do
      double(:nd3).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("stylesheet").twice
      end
    end
    let(:nd4) do
      double(:nd4).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("canonical").twice
        expect(n).to receive(:[]).with("href").and_return("http://g00gle.com/a_href")
        expect(n).to receive(:text).and_return("D")
      end
    end
    let(:nd5) do
      double(:nd5).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("external").twice
        expect(n).to receive(:[]).with("href").and_return("http://giggle.com/a_href")
        expect(n).to receive(:text).and_return("E            \r\n")
      end
    end

    before :each do
      expect(nokogiri_doc).to receive(:xpath).with("//a[@href]|//link[@href]")
      .and_return([nd1, nd2, nd3, nd4, nd5])
    end

    it "should be filtered correctly" do
      expect(subject.links.length).to eq(4)
    end

    it "should include regular a hrefs" do
      expect(subject.links).to include ["/a_href", "A"], ["http://google.com/a_href", "B"]
    end

    it "should include links" do
      expect(subject.links).to include ["http://g00gle.com/a_href", "D"], ["http://giggle.com/a_href", "E"]
    end

  end

  describe "#assets" do

    let(:nd1) do
      double(:nd1).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return(nil)
        expect(n).to receive(:[]).with("href").and_return("/a_href")
        expect(n).to receive(:text).and_return("A")
      end
    end
    let(:nd2) do
      double(:nd2).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return(nil)
        expect(n).to receive(:[]).with("href").and_return(nil)
        expect(n).to receive(:[]).with("src").and_return("http://google.com/a_href")
        expect(n).to receive(:text).and_return("B")
      end
    end
    let(:nd3) do
      double(:nd3).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("stylesheet").twice
        expect(n).to receive(:[]).with("href").and_return("/img.png")
        expect(n).to receive(:text).and_return("C")
      end
    end
    let(:nd4) do
      double(:nd4).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("icon").twice
        expect(n).to receive(:[]).with("href").and_return(nil)
        expect(n).to receive(:[]).with("src").and_return("/thingo.png")
        expect(n).to receive(:text).and_return("D")
      end
    end
    let(:nd5) do
      double(:nd5).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("external").twice
      end
    end

    before :each do
      expect(nokogiri_doc).to receive(:xpath).with("//link[@href]|//img[@src]|//script[@src]")
      .and_return([nd1, nd2, nd3, nd4, nd5])
    end

    it "should be filtered correctly" do
      expect(subject.assets.length).to eq(4)
    end

    it "should include hrefs" do
      expect(subject.assets).to include ["/a_href", "A"], ["http://google.com/a_href", "B"]
    end

    it "should include stylsheets or icons" do
      expect(subject.assets).to include ["/img.png", "C"], ["/thingo.png", "D"]
    end

  end

end

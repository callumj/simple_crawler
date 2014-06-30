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
        expect(n).to receive(:[]).with("href").and_return("/a_href").exactly(3).times
        expect(n).to receive(:text).and_return("A")
      end
    end
    let(:nd2) do
      double(:nd2).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return(nil)
        expect(n).to receive(:[]).with("href").and_return("http://google.com/a_href").exactly(3).times
        expect(n).to receive(:text).and_return("B")
      end
    end
    let(:nd3) do
      double(:nd3).tap do |n|
        expect(n).to receive(:[]).with("href").and_return("http://internet.com").twice
        expect(n).to receive(:[]).with("rel").and_return("stylesheet").twice
      end
    end
    let(:nd4) do
      double(:nd4).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("canonical").twice
        expect(n).to receive(:[]).with("href").and_return("http://g00gle.com/a_href").exactly(3).times
        expect(n).to receive(:text).and_return("D")
      end
    end
    let(:nd5) do
      double(:nd5).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("external").twice
        expect(n).to receive(:[]).with("href").and_return("http://giggle.com/a_href").exactly(3).times
        expect(n).to receive(:text).and_return("E            \r\n")
      end
    end
    let(:nd6) do
      double(:nd6).tap do |n|
        expect(n).to receive(:[]).with("href").and_return("").twice
      end
    end
    let(:nd7) do
      double(:nd6).tap do |n|
        expect(n).to receive(:[]).with("href").and_return(nil)
      end
    end

    before :each do
      expect(nokogiri_doc).to receive(:xpath).with("//a[@href]|//link[@href]")
      .and_return([nd1, nd2, nd3, nd4, nd5, nd6, nd7])
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
        expect(n).to receive(:[]).with("rel").and_return(nil).twice
        expect(n).to receive(:[]).with("href").and_return("/a_href")
        expect(n).to receive(:text).and_return("A")
        expect(n).to receive(:name).and_return("img")
      end
    end
    let(:nd2) do
      double(:nd2).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return(nil).twice
        expect(n).to receive(:[]).with("href").and_return(nil)
        expect(n).to receive(:[]).with("src").and_return("http://google.com/a_href")
        expect(n).to receive(:text).and_return("B")
        expect(n).to receive(:name).and_return("img")
      end
    end
    let(:nd3) do
      double(:nd3).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("stylesheet").exactly(4).times
        expect(n).to receive(:[]).with("href").and_return("/img.png")
        expect(n).to receive(:text).and_return("C")
      end
    end
    let(:nd4) do
      double(:nd4).tap do |n|
        expect(n).to receive(:[]).with("rel").and_return("icon").exactly(4).times
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

    context "with no commented out assets" do

      before :each do
        expect(nokogiri_doc).to receive(:xpath).with("//head/comment()").and_return([])
      end

      it "should be filtered correctly" do
        expect(subject.assets.length).to eq(4)
      end

      it "should include hrefs" do
        expect(subject.assets).to include ["/a_href", "A", "img"], ["http://google.com/a_href", "B", "img"]
      end

      it "should include stylesheets or icons" do
        expect(subject.assets).to include ["/img.png", "C", "stylesheet"], ["/thingo.png", "D", "icon"]
      end

    end

    context "with commented out assets" do

      let(:script_comment) do
        str = <<-EOF
          [if lt IE 9]>
            <script src="/App_Themes/Datacom/scripts/libs/html5shiv.js"></script>
            <script src="/App_Themes/Datacom/scripts/libs/html5shiv-printshiv.js"></script>
          <![endif]
        EOF
        double(:script_comment).tap do |s|
          expect(s).to receive(:text).and_return(str)
        end
      end

      def self.make_node_var(name, str)
        let(name) do
          double(name).tap do |s|
            expect(s).to receive(:text).and_return(str)
          end
        end
      end

      make_node_var(:other_comment1, '[if lt IE 7 ]> <html lang="en-nz" class="no-js ie6" > <![endif]')
      make_node_var(:other_comment2, '[if IE 7 ]>    <html lang="en-nz" class="no-js ie7" > <![endif]')
      make_node_var(:other_comment3, '[if IE 10 ]>    <html lang="en-nz" class="no-js ie10" > <![endif]')

      before :each do
        expect(nokogiri_doc).to receive(:xpath).with("//head/comment()").and_return([script_comment, other_comment1, other_comment2, other_comment3])
      end

      it "should be filtered correctly" do
        expect(subject.assets.length).to eq(6)
      end

      it "should include the scripts" do
        expect(subject.assets).to include ["/App_Themes/Datacom/scripts/libs/html5shiv.js", "", "script"], ["/App_Themes/Datacom/scripts/libs/html5shiv-printshiv.js", "", "script"]
      end

    end

  end

end

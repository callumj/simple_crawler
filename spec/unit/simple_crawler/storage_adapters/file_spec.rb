require 'spec_helper'

describe SimpleCrawler::StorageAdapters::File do

  let(:crawl_session) { SimpleCrawler::CrawlSession.new }

  before :each do
    expect(Dir).to receive(:exists?).with("/tmp/thing").and_return(false)
    expect(FileUtils).to receive(:mkdir_p).with("/tmp/thing")
  end

  subject { described_class.new output: "/tmp/thing", crawl_session: crawl_session }

  describe "#dump" do

    it "should generate_file(s) for each type" do
      expect(crawl_session.results_store).to receive(:contents).and_return([{contents: true}])
      expect(crawl_session.results_store).to receive(:assets_usage).and_return([["h", ["a", "b"]]])
      expect(crawl_session.results_store).to receive(:incoming_links).and_return([["j", ["c", "d"]]])
      expect(crawl_session.results_store).to receive(:local_stylesheets).and_return([{style: true}])

      expect(subject).to receive(:generate_file).with([{contents: true}], "/tmp/thing/map.xml")
      expect(subject).to receive(:generate_file).with({"h" => ["a", "b"]}, "/tmp/thing/assets.xml")
      expect(subject).to receive(:generate_file).with({"j" => ["c", "d"]}, "/tmp/thing/incoming_links.xml")
      expect(subject).to receive(:generate_file).with([{style: true}], "/tmp/thing/local_stylesheets.xml")

      subject.dump
    end

  end

  describe "#generate_file" do

    it "should build a root and write a file" do
      output = double(:output)
      contents = double(:contents)
      file_block = double(:file).tap do |f|
        expect(f).to receive(:write).with(output)
      end
      expect(subject).to receive(:build_xml).with(contents).and_return(output)

      expect(::File).to receive(:open).with("ffffile", "w").and_yield(file_block)

      subject.generate_file contents, "ffffile"
    end

  end

  describe "#build_xml" do

    it "should be able to build a simple root array" do
      items = [
        {id: "1", value: "val1"},
        {id: "2", value: "val2"},
        {id: "3", value: "val3"},
      ]

      res = subject.build_xml items
      parsed = Nokogiri::XML(res)
      expect(parsed.xpath("//items/item").length).to eq 3

      ["1", "2", "3"].each do |id|
        path = parsed.xpath("//items/item[@id=#{id}]")
        expect(path.length).to eq 1
        expect(path.xpath("value").text).to eq "val#{id}"
      end
    end

    it "should be able construct nested structures" do
      items = [
        {id: "1", assets: ["1", "2", "3"]},
        {id: "2", stuff: { key: "yes" }},
        {id: "3", things: [{id: "1", m: "m"}, {id: "2", b: "b"}]}
      ]

      res = subject.build_xml items
      parsed = Nokogiri::XML(res)

      expect(parsed.xpath("//items/item").length).to eq 3
      ["1", "2", "3"].each do |id|
        path = parsed.xpath("//items/item[@id=1]/assets/asset[text() = #{id}]")
        expect(path.text).to eq id
      end

      expect(parsed.xpath("//items/item[@id=2]/stuff/key").text).to eq "yes"

      ["1", "2"].each do |id|
        path = parsed.xpath("//items/item[@id=3]/things/thing[@id=#{id}]")

        if id == "1"
          expect(path.xpath("m").text).to eq "m"
        else
          expect(path.xpath("b").text).to eq "b"
        end
      end
    end

    it "should be able to escape data" do
      items = [
        {id: "1", value: "val1"},
        {id: "http://google.com/?val=1&val2=2", value: "val2"},
        {id: "3", value: "http://google.com/?val=1&val2=2"},
      ]

      res = subject.build_xml items
      parsed = Nokogiri::XML(res)
      expect(parsed.xpath("//items/item").length).to eq 3

      ["1", "3"].each do |id|
        path = parsed.xpath("//items/item[@id=#{id}]")
        expect(path.length).to eq 1
        if id == "1"
          expect(path.xpath("value").text).to eq "val#{id}"
        else
          child = path.xpath("value").first.children.first
          expect(child).to be_a(Nokogiri::XML::CDATA)
          expect(child.text).to eq "http://google.com/?val=1&val2=2"
        end
      end

      path = parsed.xpath("//items/item[@id='http://google.com/?val=1&val2=2']")
      expect(path.length).to eq 1
    end

  end

end
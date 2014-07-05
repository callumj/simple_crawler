require 'spec_helper'

describe SimpleCrawler::StorageAdapters::File do

  let(:crawl_session) { SimpleCrawler::CrawlSession.new }

  before :each do
    expect(Dir).to receive(:exists?).with("/tmp/thing").and_return(false)
    expect(FileUtils).to receive(:mkdir_p).with("/tmp/thing")
  end

  subject { described_class.new output: "/tmp/thing", crawl_session: crawl_session }

  describe "#build_xml" do

    it "should be able to build a simple root array" do
      items = [
        {id: "1", value: "val1"},
        {id: "2", value: "val2"},
        {id: "3", value: "val3"},
      ]

      res = subject.build_xml items
      parsed = Nokogiri::XML(res)
      expect(parsed.xpath("//item_set/item").length).to eq 3

      ["1", "2", "3"].each do |id|
        path = parsed.xpath("//item_set/item[@id=#{id}]")
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

      expect(parsed.xpath("//item_set/item").length).to eq 3
      ["1", "2", "3"].each do |id|
        path = parsed.xpath("//item_set/item[@id=1]/asset_set/asset[@id=#{id}]")
        expect(path.text).to eq id
      end

      expect(parsed.xpath("//item_set/item[@id=2]/stuff_set/stuff[@id='key']").text).to eq "yes"

      ["1", "2"].each do |id|
        path = parsed.xpath("//item_set/item[@id=3]/thing_set/thing[@id=#{id}]")

        if id == "1"
          expect(path.xpath("m").text).to eq "m"
        else
          expect(path.xpath("b").text).to eq "b"
        end
      end
    end

  end

end
require 'spec_helper'

describe SimpleCrawler::Models::Asset do

  let(:uri) { Addressable::URI.parse("http://google.com/asset3.png") }
  subject { described_class.new uri, "img" }

  it { expect(subject.type).to eq "img" }
  it { expect(subject.uri).to eq uri }

  it "should be the same as another Addressable::URI backed" do
    expect(subject).to eq described_class.new(uri, "image")
    expect(subject).to eql described_class.new(uri, "image")
  end

  it "should expose prepare for JSON output" do
    expect(subject.as_json).to eq({
      uri: "http://google.com/asset3.png",
      type: "img"
    })
  end

end

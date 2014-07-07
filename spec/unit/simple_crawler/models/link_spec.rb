require 'spec_helper'

describe SimpleCrawler::Models::Link do

  let(:uri) { Addressable::URI.parse("http://google.com/help") }
  subject { described_class.new uri }

  it { expect(subject.uri).to eq uri }

  it "should be the same as another Addressable::URI backed" do
    expect(subject).to eq described_class.new(uri)
    expect(subject).to eql described_class.new(uri)
  end

  it "should expose prepare for JSON output" do
    expect(subject).to receive(:fallback_to_missing_title).and_return("Some title")

    expect(subject.as_json).to eq({
      uri: "http://google.com/help",
      title: "Some title"
    })
  end

end

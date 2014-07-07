require 'spec_helper'

describe SimpleCrawler::Worker do

  let(:queue) { double :queue }
  let(:session) do
    double(:session).tap do |s|
      expect(s).to receive(:queue).and_return(queue).at_least(:once)
    end
  end

  it "should finish if there is nothing on the queue" do
    expect(queue).to receive(:dequeue).and_return(nil)

    expect(subject.perform(session)).to be_nil
  end

  context "handling content" do

    let(:uri) { double(:uri) }
    let(:content) { double :content }

    before :each do
      allow(SimpleCrawler.logger).to receive(:debug).with("Processing #{uri.to_s}")
    end

    before :each do
      expect(SimpleCrawler::ContentFetcher).to receive(:new).with(uri, session).and_return(content)
      expect(queue).to receive(:dequeue).and_return(uri)
    end

    it "should call ContentFetcher, get the content info and add content" do
      content_info = double :content_info
      expect(content).to receive(:content_info).and_return(content_info)
      expect(session).to receive(:add_content).with(content_info)

      subject.perform(session)
    end

    it "should handle Errors::UnknownContent" do
      expect(session).to receive(:notify_of_failure).with(uri)
      
      expect(content).to receive(:content_info) do
        raise SimpleCrawler::Errors::UnknownContent
      end

      expect(SimpleCrawler.logger).to receive(:debug).with("\tDo not know how to handle this.")

      subject.perform(session)
    end

    it "should handle StandardError" do
      expect(session).to receive(:notify_of_failure).with(uri)
      err = StandardError.new
      expect(content).to receive(:content_info) do
        raise err
      end

      expect(SimpleCrawler.logger).to receive(:error).with("Encountered error: #{err.to_s}")

      subject.perform(session)
    end

  end

end
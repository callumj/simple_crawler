require 'spec_helper'

describe SimpleCrawler::Tasks::SingleRun do

  describe ".run" do

    let(:url) { double(:url) }
    let(:output) { double(:output) }
    let(:opts) { {initial_url: url, output: output} }
    let(:session) { double(:session) }

    before :each do
      expect(SimpleCrawler::CrawlSession).to receive(:new).with(opts).and_return(session)
    end

    it "should run until peeking yields nil" do
      count = 0
      queue = double :queue
      expect(queue).to receive(:peek).exactly(3).times do
        if count == 2
          nil
        else
          count += 1
          Object.new
        end
      end
      expect(session).to receive(:queue).and_return(queue).exactly(3).times

      worker = double(:worker).tap do |w|
        expect(w).to receive(:perform).with(session).twice
      end
      expect(SimpleCrawler::Worker).to receive(:new).and_return(worker).twice

      expect(session).to receive(:dump_results)

      described_class.run url, output
    end

  end

end
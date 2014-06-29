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
    let(:faraday) { double(:faraday) }
    subject { described_class.new("http://ask.com/req/a/b?query=true&fun=ok#loc1") }

    it "should handle a Faraday error, sleeping and retrying for gt ::MAX_FARADAY_ERROR" do
      err = Faraday::Error.new "Hey!"

      expect(Faraday).to receive(:new).with("http://ask.com").and_return(faraday)
      expect(faraday).to receive(:get).with("/req/a/b?query=true&fun=ok").exactly(described_class::MAX_FARADAY_ERROR) do
        raise err
      end

      ((described_class::SLEEP_AFTER + 1)..described_class::SLEEP_SQUARE_AFTER).each do |try|
        expect(subject).to receive(:sleep).with(described_class::SLEEP_MULT * try)
      end

      ((described_class::SLEEP_SQUARE_AFTER + 1)..(described_class::MAX_FARADAY_ERROR - 1)).each do |try|
        expect(subject).to receive(:sleep).with((try.to_f * try.to_f) * described_class::SLEEP_MULT)
      end

      expect do
        subject.obtain_source
      end.to raise_error(err)
    end

    it "should handle encoding errors, falling back no encoding" do
      err = Zlib::DataError.new "Hey!"
      yielding = Struct.new(:headers)
      yielding_obj = yielding.new.tap do |i|
        i.headers = {}
      end

      try_count = 0
      expect(Faraday).to receive(:new).with("http://ask.com").and_return(faraday)
      expect(faraday).to receive(:get).with("/req/a/b?query=true&fun=ok").exactly(described_class::MAX_ZLIB_ERROR) do
        if (try_count == 0)
          expect(yielding_obj.headers.keys).to be_empty
        end

        try_count += 1
        raise err
      end.and_yield(yielding_obj)

      expect do
        subject.obtain_source
      end.to raise_error(err)

      expect(yielding_obj.headers).to eq({accept_encoding: 'none'})
    end

    it "should return a download response on success" do
      uri = URI("http://google.com")
      env = double(:env).tap do |e|
        expect(e).to receive(:url).and_return(uri)
      end

      fday_response = double(:resp).tap do |r|
        expect(r).to receive(:body).and_return("!!body!!")
        expect(r).to receive(:headers).and_return({headers: true})
        expect(r).to receive(:status).and_return(278)
        expect(r).to receive(:env).and_return(env)
      end

      expect(Faraday).to receive(:new).with("http://ask.com").and_return(faraday)
      expect(faraday).to receive(:get).with("/req/a/b?query=true&fun=ok").and_return(fday_response)

      ret = subject.obtain_source
      expect(ret.source).to eq("!!body!!")
      expect(ret.headers).to eq({headers: true})
      expect(ret.status).to eq(278)
      expect(ret.final_uri).to eq(uri)
    end
  end

end
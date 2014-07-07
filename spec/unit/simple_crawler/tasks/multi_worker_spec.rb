require 'spec_helper'

describe SimpleCrawler::Tasks::MultiWorker do

  describe ".run" do

    it "should start a session, invoking the supervisor" do

      supervisor = double(:supervisor).tap do |s|
        expect(s).to receive(:run)
      end
      session = double :session

      url = double :url
      output = double :output

      expect(SimpleCrawler::CrawlSession).to receive(:new).with(initial_url: url, output: output).and_return(session)
      expect(described_class::Supervisor).to receive(:new).with(session).and_return(supervisor)

      expect(described_class.run(url, output)).to eq supervisor
    end

  end

  describe ".client" do

    it "should create a connection, with a crawl_session proxy for a supervisor" do
      port = 8070
      host = "localyhosty"

      session = double :session
      conn = double :connection
      supervisor = double(:supervisor).tap do |s|
        expect(s).to receive(:run)
        expect(s).to receive(:run_forever=).with(true)
      end

      expect(SimpleCrawler::Client::Connection).to receive(:new).with(port, host).and_return(conn)
      expect(SimpleCrawler::Client::CrawlSession).to receive(:new).with(conn).and_return(session)
      expect(described_class::Supervisor).to receive(:new).with(session).and_return(supervisor)

      expect(described_class.client(host, port)).to eq supervisor
    end

  end

  describe SimpleCrawler::Tasks::MultiWorker::Supervisor do

    let(:session) { double :session }
    subject { described_class.new session }

    describe "#run" do

      it "should kick off a thread that runs keep_alive" do
        expect(subject).to receive(:keep_alive)
        subject.run
        subject.main_thread.join
      end

    end

    describe "#max_workers" do

      it "should default to MAX_WORKERS" do
        expect(subject.max_workers).to eq described_class::MAX_WORKERS
      end

      it "should default if empty" do
        previous = ENV["MAX_WORKERS"]
        ENV["MAX_WORKERS"] = ""
        expect(subject.max_workers).to eq described_class::MAX_WORKERS
        ENV["MAX_WORKERS"] = previous
      end

      it "should convert into a int" do
        previous = ENV["MAX_WORKERS"]
        ENV["MAX_WORKERS"] = "992"
        expect(subject.max_workers).to eq 992
        ENV["MAX_WORKERS"] = previous
      end

    end

    describe "#keep_alive" do

      let(:queue) { double :queue }
      let(:session) do
        double(:session).tap do |s|
          allow(s).to receive(:queue).and_return(queue)
        end
      end
      subject { described_class.new session }

      it "should peek into the queue and kick off a number of workers that are available" do
        worker = double(:worker).tap do |w|
          expect(w).to receive(:perform).with(session).exactly(8).times
        end

        count = 0
        expect(queue).to receive(:peek).exactly(3).times do
          count += 1
          next if count >= 3
          Object.new
        end

        workers = [double(:worker1), double(:worker2)]
        subject.instance_variable_set(:@active_workers, workers)

        expect(subject).to receive(:clean_dead_workers)

        expect(subject).to receive(:max_workers).and_return(10)

        expect(SimpleCrawler::Worker).to receive(:new).and_return(worker).exactly(8).times
        expect(subject).to receive(:sleep).with(described_class::SLEEP_FOR)

        expect(subject).to receive(:any_active_workers?).and_return(false)
        expect(session).to receive(:dump_results)

        subject.keep_alive
        threads = workers.select { |w| w.is_a?(Thread) }
        
        threads.each { |t| t.join }
      end

      it "should loop on any_active_workers?" do
        state = true
        expect(subject).to receive(:any_active_workers?).twice do
          s = state
          state = false
          s
        end

        expect(subject).to receive(:clean_dead_workers)
        expect(queue).to receive(:peek).exactly(3).times
        expect(subject).to_not receive(:max_workers)

        expect(subject).to receive(:sleep).with(described_class::SLEEP_FOR)
        expect(session).to receive(:dump_results)

        subject.keep_alive
      end

      it "should loop on running for ever" do
        state = true
        expect(subject).to receive(:any_active_workers?).and_return(false).twice
        expect(subject).to receive(:run_forever).twice do
          s = state
          state = false
          s
        end

        expect(subject).to receive(:clean_dead_workers)
        expect(queue).to receive(:peek).exactly(3).times
        expect(subject).to_not receive(:max_workers)

        expect(subject).to receive(:sleep).with(described_class::SLEEP_FOR)
        expect(session).to receive(:dump_results)

        subject.keep_alive
      end

    end

    describe "#any_active_workers?" do

      let(:w1) { double(:worker1) }
      let(:w2) { double(:worker2) }
      let(:w3) { double(:worker3) }

      before :each do
        workers = [w1, w2, w3]
        subject.instance_variable_set(:@active_workers, workers)
      end

      it "should enumerate workers and bail out when it encounters the first good worker" do
        expect(subject).to receive(:good_worker?).with(w1).and_return(false)
        expect(subject).to receive(:good_worker?).with(w2).and_return(true)
        expect(subject).to_not receive(:good_worker?).with(w3)

        expect(subject).to be_any_active_workers
      end

      it "should be false on no success" do
        expect(subject).to receive(:good_worker?).with(w1).and_return(false)
        expect(subject).to receive(:good_worker?).with(w2).and_return(false)
        expect(subject).to receive(:good_worker?).with(w3).and_return(false)

        expect(subject).to_not be_any_active_workers
      end

    end

    describe "#clean_dead_workers" do

      let(:w1) { double(:worker1) }
      let(:w2) { double(:worker2) }
      let(:w3) { double(:worker3) }

      let(:workers) { [w1, w2, w3] }

      before :each do
        subject.instance_variable_set(:@active_workers, workers)
      end

      it "should drop workers that are no longer good" do

        expect(subject).to receive(:good_worker?).with(w1).and_return(false)
        expect(subject).to receive(:good_worker?).with(w2).and_return(true)
        expect(subject).to receive(:good_worker?).with(w3).and_return(false)

        subject.clean_dead_workers
        expect(workers).to eq [w2]
      end

    end

    describe "#good_worker?" do

      let(:thread) { double :thread }

      it "should be true if thread is running" do
        expect(thread).to receive(:status).and_return("run").twice
        expect(subject).to be_good_worker(thread)
      end

      it "should be true if thread is sleeping" do
        expect(thread).to receive(:status).and_return("sleep")
        expect(subject).to be_good_worker(thread)
      end

      it "should be false otherwise" do
        expect(thread).to receive(:status).and_return(nil).twice
        expect(subject).to_not be_good_worker(thread)
      end

    end

  end

end

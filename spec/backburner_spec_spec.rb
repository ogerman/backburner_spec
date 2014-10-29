require 'spec_helper'

describe BackburnerSpec do

  before {
    BackburnerSpec.reset!
  }

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "#enqueue" do
    let(:klass) { Object }
    let(:queue_name) { :queue_name }

    it "queues the klass and args" do
      BackburnerSpec.enqueue(klass, [first_name, last_name], queue: :queue_name )
      BackburnerSpec.get_tube(queue_name).should include({:class => klass.to_s, :args => [first_name, last_name]})
    end

    it "queues the klass and an empty array" do
      BackburnerSpec.enqueue(klass, [], queue: :queue_name )
      BackburnerSpec.get_tube(queue_name).should include({:class => klass.to_s, :args => []})
    end
  end

  describe "#inline" do
    context "when not set" do
      before { BackburnerSpec.inline = false }

      it "does not perform the queued action" do
        expect {
          BackburnerSpec.enqueue(NameFromClassMethod, 1, queue: :queue_name)
        }.not_to change(NameFromClassMethod, :invocations)
      end

      it "does not change the behavior of enqueue" do
        BackburnerSpec.enqueue(NameFromClassMethod, 1, queue: :queue_name)
        BackburnerSpec.get_tube(:queue_name).should include({ class: NameFromClassMethod.to_s, args: 1 })
      end
    end

    context "when set" do
      before { BackburnerSpec.inline = true }

      it "performs the queued action" do
        expect {
          BackburnerSpec.enqueue(NameFromClassMethod, 1, queue: :queue_name)
        }.to change(NameFromClassMethod, :invocations).by(1)
      end

      it "does not enqueue" do
        BackburnerSpec.enqueue(NameFromClassMethod, 1)
        BackburnerSpec.get_tube(:queue_name).should be_empty
      end
    end
  end

  describe "#perform_all" do
    before do
      BackburnerSpec.enqueue(NameFromClassMethod, 1, queue: :queue_name )
      BackburnerSpec.enqueue(NameFromClassMethod, 2, queue: :queue_name )
      BackburnerSpec.enqueue(NameFromClassMethod, 3, queue: :queue_name )
    end

    it "performs the enqueued job" do
      expect {
        BackburnerSpec.perform_for_tube(:queue_name)
      }.to change(NameFromClassMethod, :invocations).by(3)
    end

    it "removes all items from the queue" do
      expect {
        BackburnerSpec.perform_for_tube(:queue_name)
      }.to change { BackburnerSpec.get_tube(:queue_name).empty? }.from(false).to(true)
    end
  end

  describe "#get_tube" do

    it "has an empty array if nothing queued for a class" do
      BackburnerSpec.get_tube(:my_queue).should == []
    end

    it "converts symbol names to strings" do
      pending "is it needed?"
      BackburnerSpec.get_tube(:my_queue) << 'queued'
      BackburnerSpec.queues['my_queue'].should_not be_empty
    end

    it "allows additions" do
      BackburnerSpec.get_tube(:my_queue) << 'queued'
      BackburnerSpec.get_tube(:my_queue).should_not be_empty
    end
  end

  describe "#queue_for" do
    it "raises if there is no queue defined for a class" do
      pending "should it raise?"
      expect do
        BackburnerSpec.queue_for(String)
      end.to raise_error(::Backburner::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        BackburnerSpec.queue_for(NameFromClassMethod)
      end.not_to raise_error()
    end

    it "recognizes a queue defined as a class method" do
      expect do
        BackburnerSpec.queue_for(NameFromClassMethod)
      end.not_to raise_error()
    end

  end


  describe "#reset!" do
    it "clears the queues" do
      BackburnerSpec.queue_for(NameFromClassMethod) << 'queued'
      BackburnerSpec.reset!
      BackburnerSpec.queues.should be_empty
    end

    it "resets the inline status" do
      BackburnerSpec.inline = true
      BackburnerSpec.reset!
      BackburnerSpec.inline.should be_falsey
    end
  end

  describe "bugs" do
    it "does not pollute Object" do
      expect { Object.new.constantize}.to raise_error(NoMethodError)
    end
  end


end

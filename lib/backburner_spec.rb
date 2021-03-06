require "backburner_spec/version"
require "backburner_spec/ext"
require "backburner_spec/helpers"
require "backburner_spec/matchers"

module BackburnerSpec
  include Backburner::Helpers
  extend self

  attr_accessor :inline
  attr_accessor :disable_ext

  def queues
    @queues ||= Hash.new {|h,k| h[k] = []}
  end

  def reset!
    queues.clear
    self.inline = false
  end

  def enqueue(job_class, args=[], opts={})
    data = { class: job_class.name, args: args }
    tube_name = expand_tube_name(opts[:queue]  || job_class)
    perform_or_store(tube_name, data)
  end

  def perform_for_tube(tube_name)
    tube = get_tube(tube_name)
    until tube.empty?
      perform(tube.shift)
    end
  end

  def get_tube(tube_name)
    tube_name = expand_tube_name(tube_name)
    queues[tube_name]
  end

  def perform_first_for_tube(tube_name)
    perform(get_tube(tube_name).shift)
  end

  def perform_all
    queues.keys.each {|t| perform_for_tube(t) }
  end

  def immediately_perform
    stub_foo
    yield
    unstub_foo
  end

  def queue_for(klass)
    tube_name = expand_tube_name(klass)
    get_tube(tube_name)
  end

  def job_class(class_string)
    handler = constantize(class_string) rescue nil
    raise(JobNotFound, class_string) unless handler
    handler
  end

  private 

  def perform_or_store(tube_name, payload)
    if inline
      perform(payload)
    else
      store(tube_name, payload)
    end
  end

  def store(tube_name, payload)
    queues[tube_name.to_s] << payload
  end

  def perform(payload)
    payload = code_and_parse(payload)
    job_class(payload['class']).perform(*payload['args'])
  end


  def code_and_parse(args)
    JSON.parse(args.to_json)
  end
end

config = RSpec.configuration
config.include BackburnerSpec::Helpers
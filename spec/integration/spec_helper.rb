require File.expand_path("../../spec_helper", __FILE__)

RSpec.configure do |config|
  unless ENV['LOG_SERVICE_PROJECT_ID']
    raise "Please set a LOG_SERVICE_PROJECT_ID on the environment
           before running the integration specs."
  end
end

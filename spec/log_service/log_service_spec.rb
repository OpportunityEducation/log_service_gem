require File.expand_path("../spec_helper", __FILE__)

describe LogService do
  describe "default client" do
    describe "configuring from the environment" do
      before do
        LogService.instance_variable_set(:@default_client, nil)
        ENV["LOG_SERVICE_PROJECT_ID"] = "12345"
        ENV["LOG_SERVICE_WRITE_KEY"] = "abcdewrite"
        ENV["LOG_SERVICE_READ_KEY"] = "abcderead"
        ENV["LOG_SERVICE_MASTER_KEY"] = "lalalala"
        ENV["LOG_SERVICE_API_URL"] = "http://fake.oe-log-service.herokuapp.com:fakeport"
        ENV["LOG_SERVICE_PROXY_URL"] = "http://proxy.oe-log-service.herokuapp.com:proxyport"
        ENV["LOG_SERVICE_PROXY_TYPE"] = "http"
      end

      let(:client) { LogService.send(:default_client) }

      it "should set a project id from the environment" do
        expect(client.project_id).to eq "12345"
      end

      it "should set a write key from the environment" do
        expect(client.write_key).to eq "abcdewrite"
      end

      it "should set a read key from the environment" do
        expect(client.read_key).to eq "abcderead"
      end

      it "should set a master key from the environment" do
        expect(client.master_key).to eq "lalalala"
      end

      it "should set an api host from the environment" do
        expect(client.api_url).to eq "http://fake.oe-log-service.herokuapp.com:fakeport"
      end

      it "should set an proxy host from the environment" do
        expect(client.proxy_url).to eq "http://proxy.oe-log-service.herokuapp.com:proxyport"
      end

      it "should set an proxy type from the environment" do
        expect(client.proxy_type).to eq "http"
      end
    end
  end

  describe "LogService delegation" do
    it "should memoize the default client, retaining settings" do
      LogService.project_id = "new-abcde"
      expect(LogService.project_id).to eq "new-abcde"
    end

    after do
      LogService.instance_variable_set(:@default_client, nil)
    end
  end

  describe "forwardable" do
    before do
      @default_client = double("client")
      allow(LogService).to receive(:default_client) { @default_client }
    end

    [:project_id, :write_key, :read_key, :api_url, :proxy_url, :proxy_type].each do |_method|
      it "should forward the #{_method} method" do
        expect(@default_client).to receive(_method)
        LogService.send(_method)
      end
    end

    [:project_id, :write_key, :read_key, :master_key, :api_url].each do |_method|
      it "should forward the #{_method} method" do
        expect(@default_client).to receive(_method)
        LogService.send(_method)
      end
    end

    [:project_id=, :write_key=, :read_key=, :master_key=, :api_url=].each do |_method|
      it "should forward the #{_method} method" do
        expect(@default_client).to receive(_method).with("12345")
        LogService.send(_method, "12345")
      end
    end

    [:publish, :publish_async, :publish_batch, :publish_batch_async].each do |_method|
      it "should forward the #{_method} method" do
        expect(@default_client).to receive(_method).with("users", {})
        LogService.send(_method, "users", {})
      end
    end

    # pull the query methods list at runtime in order to ensure
    # any new methods have a corresponding delegator
    LogService::Client::QueryingMethods.instance_methods.each do |_method|
      it "should forward the #{_method} query method" do
        expect(@default_client).to receive(_method).with("users", {})
        LogService.send(_method, "users", {})
      end
    end
  end

  describe "logger" do
    it "should be set to info" do
      expect(LogService.logger.level).to eq Logger::INFO
    end
  end
end

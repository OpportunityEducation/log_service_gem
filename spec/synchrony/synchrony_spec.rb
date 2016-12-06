require File.expand_path("../spec_helper", __FILE__)

describe LogService::HTTP::Async do
  let(:project_id) { "12345" }
  let(:write_key) { "abcdewrite" }
  let(:collection) { "users" }
  let(:api_url) { "https://fake-oe-log-service.herokuapp.com" }
  let(:event_properties) { { "name" => "Bob" } }
  let(:api_success) { true }
  let(:batch_api_success) { { "created" => true } }
  let(:events) {
        {
          :purchases => [
            { :price => 10 },
            { :price => 11 }
          ],
          :signups => [
            { :name => "bob" },
            { :name => "bill" }
          ]
        }
      }

  describe "synchrony" do
    before do
      @client = LogService::Client.new(
        :project_id => project_id, :write_key => write_key,
        :api_url => api_url)
    end

    describe "success" do
      it "should post the event data" do
        stub_log_service_post(api_event_collection_resource_url(api_url, collection), 201, api_success)
        EM.synchrony {
          @client.publish_async(collection, event_properties)
          expect_log_service_post(api_event_collection_resource_url(api_url, collection), event_properties, "async", write_key)
          EM.stop
        }
      end

      it "should receive the right response 'synchronously'" do
        stub_log_service_post(api_event_collection_resource_url(api_url, collection), 201, api_success)
        EM.synchrony {
          @client.publish_async(collection, event_properties).should == api_success
          EM.stop
        }
      end
    end

    describe "batch success" do
      it "should post the event data" do
        stub_log_service_post(api_event_resource_url(api_url), 201, api_success)
        EM.synchrony {
          @client.publish_batch_async(events)
          expect_log_service_post(api_event_resource_url(api_url), events, "async", write_key)
          EM.stop
        }
      end

      it "should receive the right response 'synchronously'" do
        stub_log_service_post(api_event_resource_url(api_url), 201, api_success)
        EM.synchrony {
          @client.publish_batch_async(events).should == api_success
          EM.stop
        }
      end
    end

    describe "failure" do
      it "should raise an exception" do
        stub_request(:post, api_event_collection_resource_url(api_url, collection)).to_timeout
        e = nil
        EM.synchrony {
          begin
            @client.publish_async(collection, event_properties).should == api_success
          rescue Exception => exception
            e = exception
          end
          e.class.should == LogService::HttpError
          e.message.should == "Log Service Exception: HTTP em-synchrony publish_async error: WebMock timeout error"
          EM.stop
        }
      end
    end

    describe "batch failure" do
      it "should raise an exception" do
        stub_request(:post, api_event_resource_url(api_url)).to_timeout
        e = nil
        EM.synchrony {
          begin
            @client.publish_batch_async(events).should == api_success
          rescue Exception => exception
            e = exception
          end
          e.class.should == LogService::HttpError
          e.message.should == "Log Service Exception: HTTP em-synchrony publish_async error: WebMock timeout error"
          EM.stop
        }
      end
    end
  end
end

require File.expand_path("../spec_helper", __FILE__)

describe "OE Log Service API" do
  let(:project_id) { ENV['LOG_SERVICE_PROJECT_ID'] }
  let(:write_key) { ENV['LOG_SERVICE_WRITE_KEY'] }

  def wait_for_count(event_collection, count)
    attempts = 0
    while attempts < 30
      break if LogService.count(event_collection) == count
      attempts += 1
      sleep(1)
    end
  end

  describe "publishing" do
    let(:collection) { "User posts.new" }
    let(:event_properties) { { "name" => "Bob" } }
    let(:api_success) { { "created" => true } }

    describe "success" do
      it "should return a created status for a valid post" do
        LogService.publish(collection, event_properties).should == api_success
      end
    end

    describe "failure" do
      it "should raise a not found error if an invalid project id" do
        client = LogService::Client.new(:project_id => "riker", :write_key => "whatever")
        expect {
          client.publish(collection, event_properties)
        }.to raise_error(LogService::NotFoundError)
      end

      it "should succeed if a non-url-safe event collection is specified" do
        LogService.publish("infinite possibilities", event_properties).should == api_success
      end
    end

    describe "async" do
      # no TLS support in EventMachine on jRuby
      unless defined?(JRUBY_VERSION)

        it "should publish the event and trigger callbacks" do
          EM.run {
            LogService.publish_async(collection, event_properties).callback { |response|
              begin
                response.should == api_success
              ensure
                EM.stop
              end
            }.errback { |error|
              EM.stop
              fail error
            }
          }
        end

        it "should publish to non-url-safe collections" do
          EM.run {
            LogService.publish_async("foo bar", event_properties).callback { |response|
              begin
                response.should == api_success
              ensure
                EM.stop
              end
            }
          }
        end
      end
    end

    describe "batch" do
      it "should publish a batch of events" do
        LogService.publish_batch(
          :batch_signups => [
            { :name => "bob" },
            { :name => "ted" }
          ],
          :batch_purchases => [
            { :price => 30 },
            { :price => 40 }
          ]
        ).should == {
          "batch_purchases" => [
            { "success" => true },
            { "success" => true }
          ],
          "batch_signups" => [
            { "success" => true },
            { "success"=>true }
          ]}
      end
    end
  end

  describe "batch_async" do
      # no TLS support in EventMachine on jRuby
      unless defined?(JRUBY_VERSION)
        let(:api_success) { {"batch_purchases"=>[{"success"=>true}, {"success"=>true}], "batch_signups"=>[{"success"=>true}, {"success"=>true}]} }
        it "should publish the event and trigger callbacks" do
          EM.run {
            LogService.publish_batch_async(
              :batch_signups => [
                { :name => "bob" },
                { :name => "ted" }
              ],
              :batch_purchases => [
                { :price => 30 },
                { :price => 40 }
              ]).callback { |response|
              begin
                response.should == api_success
              ensure
                EM.stop
              end
            }.errback { |error|
              EM.stop
              fail error
            }
          }
        end
      end
    end

  describe "queries" do
    let(:read_key) { ENV['LOG_SERVICE_READ_KEY'] }
    let(:event_collection) { @event_collection }
    let(:returns_event_collection) { @returns_event_collection }

    before(:all) do
      @event_collection = "purchases_" + rand(100000).to_s
      @returns_event_collection = "returns_" + rand(100000).to_s

      LogService.publish(@event_collection, {
        :username => "bob",
        :price => 10
      })
      LogService.publish(@event_collection, {
        :username => "ted",
        :price => 20
      })
      LogService.publish(@returns_event_collection, {
        :username => "bob",
        :price => 30
      })

      # poll the count to know when to continue
      wait_for_count(@event_collection, 2)
      wait_for_count(@returns_event_collection, 1)
    end

    it "should return a valid count_unique" do
      LogService.count_unique(event_collection, :target_property => "price").should == 2
    end

    it "should return a valid count with group_by" do
      response = LogService.average(event_collection, :group_by => "username", :target_property => "price")
      bobs_response = response.select { |result| result["username"] == "bob" }.first
      bobs_response["result"].should == 10
      teds_response = response.select { |result| result["username"] == "ted" }.first
      teds_response["result"].should == 20
    end

    it "should return a valid count with multi-group_by" do
      response = LogService.average(event_collection, :group_by => ["username", "price"], :target_property => "price")
      bobs_response = response.select { |result| result["username"] == "bob" }.first
      bobs_response["result"].should == 10
      bobs_response["price"].should == 10
      teds_response = response.select { |result| result["username"] == "ted" }.first
      teds_response["result"].should == 20
      teds_response["price"].should == 20
    end

    it "should return a valid sum" do
      LogService.sum(event_collection, :target_property => "price").should == 30
    end

    it "should return a valid minimum" do
      LogService.minimum(event_collection, :target_property => "price").should == 10
    end

    it "should return a valid maximum" do
      LogService.maximum(event_collection, :target_property => "price").should == 20
    end

    it "should return a valid average" do
      LogService.average(event_collection, :target_property => "price").should == 15
    end

    it "should return a valid median" do
      LogService.median(event_collection, :target_property => "price").should == 10
    end

    it "should return a valid percentile" do
      LogService.percentile(event_collection, :target_property => "price", :percentile => 50).should == 10
      LogService.percentile(event_collection, :target_property => "price", :percentile => 100).should == 20
    end

    it "should return a valid select_unique" do
      results = LogService.select_unique(event_collection, :target_property => "price")
      results.sort.should == [10, 20].sort
    end

    it "should return a valid extraction" do
      results = LogService.extraction(event_collection)
      results.length.should == 2
      results.all? { |result| result["log_service"] }.should be_true
      results.map { |result| result["price"] }.sort.should == [10, 20]
      results.map { |result| result["username"] }.sort.should == ["bob", "ted"]
    end

    it "should return a valid extraction of one property name" do
      results = LogService.extraction(event_collection, :property_names => "price")
      results.length.should == 2
      results.any? { |result| result["log_service"] }.should be_false
      results.map { |result| result["price"] }.sort.should == [10, 20]
      results.map { |result| result["username"] }.sort.should == [nil, nil]
    end

    it "should return a valid extraction of more than one property name" do
      results = LogService.extraction(event_collection, :property_names => ["price", "username"])
      results.length.should == 2
      results.any? { |result| result["log_service"] }.should be_false
      results.map { |result| result["price"] }.sort.should == [10, 20]
      results.map { |result| result["username"] }.sort.should == ["bob", "ted"]
    end

    it "should return a valid funnel" do
      steps = [{
        :event_collection => event_collection,
        :actor_property => "username"
      }, {
        :event_collection => @returns_event_collection,
        :actor_property => "username"
      }]
      results = LogService.funnel(:steps => steps)
      results.should == [2, 1]
    end

    it "should return all keys of valid funnel if full result option is passed" do
      steps = [{
        :event_collection => event_collection,
        :actor_property => "username"
      }, {
        :event_collection => @returns_event_collection,
        :actor_property => "username"
      }]
      results = LogService.funnel({ :steps => steps }, { :response => :all_keys })
      results["result"].should == [2, 1]
    end

    it "should apply filters" do
      LogService.count(event_collection, :filters => [{
        :property_name => "username",
        :operator => "eq",
        :property_value => "ted"
      }]).should == 1
    end
  end

  describe "deletes" do
    let(:event_collection) { "delete_test_#{rand(10000)}" }

    before do
      LogService.publish(event_collection, :delete => "me")
      LogService.publish(event_collection, :delete => "you")
      wait_for_count(event_collection, 2)
    end

    it "should delete the event" do
      LogService.delete(event_collection, :filters => [
        { :property_name => "delete", :operator => "eq", :property_value => "me" }
      ])
      wait_for_count(event_collection, 1)
      results = LogService.extraction(event_collection)
      results.length.should == 1
      results.first["delete"].should == "you"
    end
  end

   describe "project methods" do
     let(:event_collection) { "test_collection" }

     describe "event_collections" do
       # requires a project with at least 1 collection
       it "should return the project's collections as JSON" do
         first_collection = LogService.event_collections.first
         first_collection["properties"]["log_service.timestamp"].should == "datetime"
       end
     end

     describe "event_collection" do
       # requires a project with at least 1 collection
       it "should return the project's named collection as JSON" do
         first_collection = LogService.event_collection(:event_collection)
         first_collection["properties"]["log_service.timestamp"].should == "datetime"
       end
     end

     describe "project_info" do
       it "should return the project info as JSON" do
         LogService.project_info["url"].should =~ Regexp.new(project_id)

       end
     end
   end
end

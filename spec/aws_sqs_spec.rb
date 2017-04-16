require 'spec_helper.rb'
describe "AWS::SQS" do

  let(:queue_url){"https://sqs.us-west-2.amazonaws.com/943154236803/gabrielzuqueto_eti_br"}
  let(:queue_name){:gabrielzuqueto_eti_br}

  before do
    @client_aws_sqs = Aws::SQS::Client.new
  end

  describe "When called create_queue" do
    it "Should return error if queue_name is invalid" do
      expect { @client_aws_sqs.create_queue({queue_name: nil}) }.to raise_error(ArgumentError)
    end

    it "Should success" do
      @client_aws_sqs.stub_responses(:create_queue, queue_url: queue_url)
      response = @client_aws_sqs.create_queue({queue_name: queue_name})
      expect ( response.successful? ).should be_truthy
      expect ( response.queue_url ).should eq(queue_url)
    end
  end

  describe "When called purge_queue" do
    it "Should return error if queue_url is invalid" do
      expect { @client_aws_sqs.purge_queue({queue_url: nil}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.purge_queue({queue_url: ""}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.purge_queue({queue_url: "something"}) }.to raise_error(ArgumentError)
    end

    it "Should return error if queue doesn't exists" do
      @client_aws_sqs.stub_responses(:purge_queue, 'NonExistentQueue')
      expect { @client_aws_sqs.purge_queue({queue_url: queue_url}) }.to raise_error(Aws::SQS::Errors::NonExistentQueue)
    end

    it "Should success" do
      response = @client_aws_sqs.purge_queue({queue_url: queue_url})
      expect ( response.successful? ).should be_truthy
      expect ( response ).should eq(Aws::EmptyStructure.new)
    end
  end

  describe "When called delete_queue" do
    it "Should return error if queue_url is invalid" do
      expect { @client_aws_sqs.delete_queue({queue_url: nil}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_queue({queue_url: ""}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_queue({queue_url: "something"}) }.to raise_error(ArgumentError)
    end

    it "Should return error if queue doesn't exists" do
      @client_aws_sqs.stub_responses(:delete_queue, 'NonExistentQueue')
      expect { @client_aws_sqs.delete_queue({queue_url: queue_url}) }.to raise_error(Aws::SQS::Errors::NonExistentQueue)
    end

    it "Should success" do
      response = @client_aws_sqs.delete_queue({queue_url: queue_url})
      expect ( response.successful? ).should be_truthy
      expect ( response ).should eq(Aws::EmptyStructure.new)
    end
  end

  describe "When called get_queue_attributes" do
    it "Should return error if queue_name is invalid" do
      expect { @client_aws_sqs.delete_queue({queue_url: nil}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_queue({queue_url: ""}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_queue({queue_url: "something"}) }.to raise_error(ArgumentError)
    end

    describe "and expect returns successful" do
      before do
        @client_aws_sqs.stub_responses(:get_queue_attributes, attributes: {
          "ApproximateNumberOfMessages" => "10",
          "ApproximateNumberOfMessagesNotVisible" => "8",
          "ApproximateNumberOfMessagesDelayed" => "0"
        })
        @response = @client_aws_sqs.get_queue_attributes({queue_url: queue_url, attribute_names: [
          "ApproximateNumberOfMessages",
          "ApproximateNumberOfMessagesNotVisible",
          "ApproximateNumberOfMessagesDelayed"
        ]})
        expect ( @response.successful? ).should be_truthy
      end

      it "Should return the requested attributes - model 1" do
        expect ( @response.attributes.length ).should eq(3)
        expect ( @response.attributes["ApproximateNumberOfMessages"] ).should eq("10")
        expect ( @response.attributes["ApproximateNumberOfMessagesNotVisible"] ).should eq("8")
        expect ( @response.attributes["ApproximateNumberOfMessagesDelayed"] ).should eq("0")
      end

      it "Should return the requested attributes - model 2" do
        expected_response = Aws::SQS::Types::GetQueueAttributesResult.new(attributes: {
          "ApproximateNumberOfMessages"=>"10",
          "ApproximateNumberOfMessagesNotVisible"=>"8",
          "ApproximateNumberOfMessagesDelayed"=>"0"
        })
        expect ( @response ).should eq(expected_response)
      end
   end
  end

  describe "When called get_queue_url" do
    it "Should return NonExistentQueue error" do
      @client_aws_sqs.stub_responses(:get_queue_url, 'NonExistentQueue')
      expect { @client_aws_sqs.get_queue_url({queue_name: queue_name}) }.to raise_error(Aws::SQS::Errors::NonExistentQueue)
    end

    it "Should return queue URL" do
      @client_aws_sqs.stub_responses(:get_queue_url, queue_url: queue_url)
      expect ( @client_aws_sqs.get_queue_url({queue_name: queue_name}).queue_url ).should eq(queue_url)
    end
  end

  describe "When called send_message" do
    it "Should return ArgumentError if queue_url is invalid URL" do
      expect { @client_aws_sqs.send_message({queue_url: "", message_body: "something" }) }.to raise_error(ArgumentError)
    end

    it "Should return ArgumentError if message_body is nil" do
      expect { @client_aws_sqs.send_message({queue_url: queue_url, message_body: nil }) }.to raise_error(ArgumentError)
    end

    it "Should return success" do
      expect ( @client_aws_sqs.send_message({queue_url: queue_url, message_body: "something" }).successful? ).should be_truthy
    end
  end

  describe "When called receive_message" do
    it "Should return ArgumentError if queue_url is invalid URL" do
      expect { @client_aws_sqs.receive_message({queue_url: ""}) }.to raise_error(ArgumentError)
    end

    it "Should return one message" do
      @client_aws_sqs.stub_responses(:receive_message, messages: [body: "something"])
      response = @client_aws_sqs.receive_message({queue_url: queue_url})
      expect ( response.successful? ).should be_truthy
      expect ( response.messages.length ).should eq(1)
      expect ( response.messages.first.class).should eq(Aws::SQS::Types::Message)
      expect ( response.messages.first.body).should eq("something")
    end

    it "Should return two messages" do
      @client_aws_sqs.stub_responses(:receive_message, messages: [{body: "something"}, {body: "anything"}])
      response = @client_aws_sqs.receive_message({queue_url: queue_url, max_number_of_messages: 10})
      expect ( response.successful? ).should be_truthy
      expect ( response.messages.length ).should eq(2)
      expect ( response.messages.first.body).should eq("something")
      expect ( response.messages.last.body).should eq("anything")
    end

    it "Should return no messages" do
      @client_aws_sqs.stub_responses(:receive_message, messages: [])
      response = @client_aws_sqs.receive_message({queue_url: queue_url})
      expect ( response.successful? ).should be_truthy
      expect ( response.messages.length ).should eq(0)
    end
  end

  describe "When called delete_message" do
    it "Should return ArgumentError if queue_url is invalid URL" do
      expect { @client_aws_sqs.delete_message({queue_url: "", receipt_handle: "something"}) }.to raise_error(ArgumentError)
    end

    it "Should return ArgumentError if receipt_handle is invalid" do
      expect { @client_aws_sqs.delete_message({queue_url: queue_url, receipt_handle: nil}) }.to raise_error(ArgumentError)
    end

    it "Should return success" do
      response = @client_aws_sqs.delete_message({queue_url: queue_url, receipt_handle: "something"})
      expect ( response.successful? ).should be_truthy
      expect ( response ).should eq(Aws::EmptyStructure.new)
    end
  end

  describe "When called delete_message_batch" do
    it "Should return ArgumentError if queue_url is invalid URL" do
      expect { @client_aws_sqs.delete_message_batch({queue_url: "", entries: []}) }.to raise_error(ArgumentError)
    end

    it "Should return ArgumentError if entries is invalid" do
      expect { @client_aws_sqs.delete_message_batch({queue_url: queue_url, entries: nil}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_message_batch({queue_url: queue_url, entries: ""}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_message_batch({queue_url: queue_url, entries: [{id: nil, receipt_handle: "something"}]}) }.to raise_error(ArgumentError)
      expect { @client_aws_sqs.delete_message_batch({queue_url: queue_url, entries: [{id: "something", receipt_handle: nil}]}) }.to raise_error(ArgumentError)
    end

    it "Should return success" do
      expect ( @client_aws_sqs.delete_message_batch({queue_url: queue_url, entries: [{id: "something", receipt_handle: "something"}, {id: "anything", receipt_handle: "anything"}]}).successful? ).should be_truthy
    end
  end

  describe "When use poll" do
    before do
      @poller_aws_sqs = Aws::SQS::QueuePoller.new(queue_url, {max_number_of_messages:10, skip_delete: true, wait_time_seconds: nil, visibility_timeout: 60})
      @poller_aws_sqs.before_request { |stats| throw :stop_polling if stats.received_message_count >= 2 }
      @poller_aws_sqs.client.stub_responses(:receive_message, messages: [
        {
          message_id: "something",
          receipt_handle: "something",
          body: "something"
        },
        {
          message_id: "anything",
          receipt_handle: "anything",
          body: "anything"
        }
      ])
    end

    it "Should receive messages" do
      received_messages = []
      @poller_aws_sqs.poll do |messages, stats|
        messages.each do |message|
          received_messages << message
        end
      end
      expect ( received_messages.length ).should eq(2)
      expect ( received_messages.first.body ).should eq("something")
      expect ( received_messages.last.body ).should eq("anything")
    end
  end
end
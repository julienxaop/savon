require "spec_helper"

describe Savon::Client do
  before { @client = Savon::Client.new EndpointHelper.wsdl_endpoint }

  it "is initialized with a SOAP endpoint String" do
    Savon::Client.new EndpointHelper.wsdl_endpoint
  end

  it "accepts a proxy URI passed in via options" do
    Savon::Client.new EndpointHelper.wsdl_endpoint, :proxy => 'http://proxy'
  end

  it "accepts settings for SSL client authentication via options" do
    Savon::Client.new EndpointHelper.wsdl_endpoint, :ssl => {
      :client_cert => "client cert",
      :client_key => "client key",
      :ca_file => "ca file",
      :verify => OpenSSL::SSL::VERIFY_PEER
    }
  end

  it "has a getter for accessing the Savon::WSDL" do
    @client.wsdl.should be_a Savon::WSDL
  end

  it "has a getter for accessing the Savon::Request" do
    @client.request.should be_a Savon::Request
  end

  it "responds to SOAP actions while still behaving as usual otherwise" do
    WSDLFixture.authentication(:operations).keys.each do |soap_action|
      @client.respond_to?(soap_action).should be_true
    end

    @client.respond_to?(:object_id).should be_true
    @client.respond_to?(:some_undefined_method).should be_false
  end

  it "dispatches SOAP calls via method_missing and returns the Savon::Response" do
    @client.authenticate.should be_a Savon::Response
  end

  describe "disabling retrieving and parsing the WSDL document" do
    it "can be done globally for every instance of Savon::Client" do
      @client.wsdl?.should be_true
      Savon::Client.wsdl = false

      expect_the_wsdl_to_be_disabled
      @client.authenticate.should be_a Savon::Response

      Savon::Client.wsdl = true
    end

    it "can be done per request" do
      @client.wsdl = false

      expect_the_wsdl_to_be_disabled
      @client.authenticate.should be_a Savon::Response
    end

    def expect_the_wsdl_to_be_disabled
      @client.wsdl?.should be_false
      [:respond_to?, :operations, :namespace_uri].each do |method|
        Savon::WSDL.any_instance.expects(method).never
      end
    end
  end

  it "raises a Savon::SOAPFault in case of a SOAP fault" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint(:soap_fault)
    lambda { client.authenticate }.should raise_error Savon::SOAPFault
  end

  it "raises a Savon::HTTPError in case of an HTTP error" do
    client = Savon::Client.new EndpointHelper.wsdl_endpoint(:http_error)
    lambda { client.authenticate }.should raise_error Savon::HTTPError
  end

  it "yields the SOAP object to a block when it expects one argument" do
    @client.authenticate { |soap| soap.should be_a Savon::SOAP }
  end

  it "yields the SOAP and WSSE object to a block when it expects two argument" do
    @client.authenticate do |soap, wsse|
      soap.should be_a Savon::SOAP
      wsse.should be_a Savon::WSSE
    end
  end

  it "still raises a NoMethodError for undefined methods" do
    lambda { @client.some_undefined_method }.should raise_error NoMethodError
  end

end

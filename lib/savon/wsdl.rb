module Savon

  # Savon::WSDL
  #
  # Represents the WSDL document.
  class WSDL

    # Initializer, expects a Savon::Request.
    def initialize(request)
      @request = request
    end

    # Returns the namespace URI of the WSDL.
    def namespace_uri
      @namespace_uri ||= stream.namespace_uri
    end

    # Returns an Array of available SOAP actions.
    def soap_actions
      @soap_actions ||= stream.operations.keys
    end

    # Returns a Hash of SOAP operations including their corresponding
    # SOAP actions and inputs.
    def operations
      @operations ||= stream.operations
    end

    # Returns +true+ for available methods and SOAP actions.
    def respond_to?(method)
      return true if soap_actions.include? method
      super
    end

    # Returns the raw WSDL document.
    def to_s
      @document ||= @request.wsdl.body
    end

  private

    # Returns the Savon::WSDLStream.
    def stream
      unless @stream
        @stream = WSDLStream.new
        REXML::Document.parse_stream to_s, @stream
      end
      @stream
    end

  end

  # Savon::WSDLStream
  #
  # Stream listener for parsing the WSDL document.
  class WSDLStream

    # Defines the main sections of a WSDL document.
    Sections = %w(definitions types message portType binding service)

    def initialize
      @depth, @operations = 0, {}
    end

    # Returns the namespace URI from the WSDL document.
    attr_reader :namespace_uri

    # Returns the SOAP operations found in the WSDL document.
    attr_reader :operations
 
    # Hook method called when the stream parser encounters a starting tag.
    def tag_start(tag, attrs)
      @depth += 1
      tag = tag.strip_namespace

      @section = tag.to_sym if @depth <= 2 && Sections.include?(tag)
      @namespace_uri ||= attrs["targetNamespace"] if @section == :definitions

      operation_from tag, attrs if @section == :binding && tag == "operation"
    end

    # Hook method called when the stream parser encounters a closing tag.
    def tag_end(tag)
      @depth -= 1
    end

    # Stores available operations from a given tag +name+ and +attrs+.
    def operation_from(tag, attrs)
      @action = attrs["name"] if attrs["name"]

      if attrs["soapAction"]
        @action = attrs["soapAction"] unless attrs["soapAction"].blank?
        input = @action.split("/").last
        @operations[input.snakecase.to_sym] = { :action => @action, :input => input }
      end
    end

    # Catches calls to unimplemented hook methods.
    def method_missing(method, *args)
    end

  end
end

module Connector::Adapters
  class Base
    class ExecutionError < StandardError; end

    def initialize(connector)
      @connector = connector
      @credential = connector.credential
    end

    def test_connection!
      raise NotImplementedError
    end

    def call(action, params)
      raise NotImplementedError
    end
  end
end

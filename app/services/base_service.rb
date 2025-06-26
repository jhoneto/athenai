class BaseService
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  def initialize(*args, **kwargs)
    # Override in subclasses
  end

  def call
    raise NotImplementedError, "Subclasses must implement #call method"
  end

  private

  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end

  def failure(error, data = {})
    ServiceResult.new(success: false, error: error, data: data)
  end
end

class ServiceResult
  attr_reader :data, :error

  def initialize(success:, data: {}, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end

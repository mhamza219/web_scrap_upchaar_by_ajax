class BaseService
  def self.call(*args)
    new(*args).call
  end

  def initialize(*args)
    @args = args
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  attr_reader :args
end 
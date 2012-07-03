module Famili
  class LazyValue
    def initialize
      @block = proc
    end

    def call
      @value ||= @block.call
    end
  end
end
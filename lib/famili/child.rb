module Famili
  class Child < BasicObject
    def initialize(mother, attributes)
      @mother = mother
      @attributes = attributes
    end

    def method_missing(name)
      if @mother.respond_to?(name)
        @mother.send(name)
      else
        evaluate_value(name.to_sym)
      end
    end

    def born
      @hash = {}
      @attributes.keys.each { |name| evaluate_value(name) }
      @mother.class.model_class.new(@hash)
    end

    private

    def evaluate_value(name)
      value = @hash[name]
      if value.nil? && !@hash.key?(name)
        attribute_value = @attributes[name]
        @hash[name] = value = attribute_value.is_a?(::Proc) ? instance_exec(&attribute_value) : attribute_value
      end
      value
    end
  end
end
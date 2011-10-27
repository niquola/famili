module Famili
  class Child < BasicObject
    def initialize(mother, attributes)
      @mother = mother
      @attributes = attributes
    end

    def method_missing(name, *arguments)
      if @mother.respond_to?(name)
        @mother.send(name, *arguments)
      else
        evaluate_value(name.to_sym, *arguments)
      end
    end

    def born
      @unresolved_keys = @attributes.keys
      @model = @mother.class.model_class.new
      evaluate_value(@unresolved_keys.first) until @unresolved_keys.empty?
      @model
    end

    private

    def evaluate_value(name, *arguments)
      if @unresolved_keys.include?(name)
        @unresolved_keys.delete(name)
        attribute_value = @attributes[name]
        attribute_value = instance_exec(&attribute_value) if attribute_value.is_a?(::Proc)
        @model.send("#{name}=", attribute_value)
      else
        @model.send(name, *arguments)
      end
    end
  end
end
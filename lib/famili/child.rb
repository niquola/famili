module Famili
  class Child < BasicObject
    attr_reader :mother

    def initialize(mother, attributes)
      @mother = mother
      @attributes = attributes
    end

    def born
      @unresolved_property_names = @attributes.keys
      @model = @mother.class.model_class.new
      @meta_class = @model.singleton_class
      @model.instance_variable_set(:@__famili_child__, self)
      define_method_stub(:method_missing) do |name, *args|
        mother = @__famili_child__.mother
        if mother.respond_to?(name)
          mother.send(name, *args)
        else
          super
        end
      end
      @unresolved_property_names.each do |key|
        define_property_stub(key)
      end
      resolve_property(@unresolved_property_names.first) until @unresolved_property_names.empty?
      undefine_method_stub(:method_missing)
      @model
    end

    def munge(property_name)
      "__famili_child_proxied_#{property_name}"
    end

    def resolve_property(name)
      @unresolved_property_names.delete(name)
      undefine_property_stub(name)
      attribute_value = @attributes[name]
      attribute_value = @model.instance_exec(&attribute_value) if attribute_value.is_a?(::Proc)
      @model.send("#{name}=", attribute_value)
    end

    def undefine_method_stub(method_name)
      munged_name = munge(method_name)
      @meta_class.send(:alias_method, method_name, munged_name)
      @meta_class.send(:remove_method, munged_name)
    end

    alias :undefine_property_stub :undefine_method_stub

    def define_property_stub(property_name)
      define_method_stub property_name do
        @__famili_child__.resolve_property(property_name)
      end
    end

    def define_method_stub(method_name, &block)
      @meta_class.send(:alias_method, munge(method_name), method_name) if @model.respond_to?(method_name)
      @meta_class.send(:define_method, method_name, &block)
    end
  end
end
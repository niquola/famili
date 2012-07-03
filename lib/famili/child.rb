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
          send(@__famili_child__.munge(:method_missing), name, *args)
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
      if attribute_value.is_a?(::Proc)
        attribute_value = @model.instance_exec(&attribute_value)
      elsif attribute_value.respond_to?(:call)
        attribute_value = attribute_value.call
      end
      attribute_value = attribute_value.build if attribute_value.is_a?(::Famili::Father)
      @model.send("#{name}=", attribute_value)
    end

    def define_property_stub(property_name)
      define_method_stub property_name do
        @__famili_child__.resolve_property(property_name)
      end if @model.respond_to?(property_name)
    end

    def undefine_property_stub(property_name)
      undefine_method_stub(property_name) if @meta_class.send(:method_defined?, munge(property_name))
    end

    def define_method_stub(method_name, &block)
      @meta_class.send(:alias_method, munge(method_name), method_name)
      @meta_class.send(:define_method, method_name, &block)
    end

    def undefine_method_stub(method_name)
      munged_name = munge(method_name)
      if @meta_class.send(:method_defined?, munged_name)
        @meta_class.send(:alias_method, method_name, munged_name)
        @meta_class.send(:remove_method, munged_name)
      else
        @meta_class.send(:remove_method, method_name)
      end
    end
  end
end
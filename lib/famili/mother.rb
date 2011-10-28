require 'date'
require 'famili/father'

module Famili
  class Mother
    def before_save(model)
    end

    def after_create(model)
    end

    def unique
      "#{"%10.6f" % Time.now.to_f}#{object_id.abs}"
    end

    def sequence_number
      @sequence_number||= self.class.objects_sequence_number
    end

    class << self
      alias :class_name :name

      def objects_sequence_number
        @sequence_number ||=0
        @sequence_number += 1
      end

      def parent_class=(klass)
        @parent_class = klass
      end

      def parent_class
        @parent_class
      end

      def inherited(child)
        child.parent_class = self
      end

      def name(&block)
        return class_name unless block_given?
        field(:name, &block)
      end

      def method_missing(method, &block)
        return field(method, &block) if block_given?
        super
      end

      def attributes
        @attributes||=parent_class && parent_class.attributes.clone || {}
        @attributes
      end

      def field(method, &block)
        attributes[method] = block
      end

      def father
        @father ||= Famili::Father.new(self.new, attributes)
      end

      def create(opts = {})
        father.create(opts)
      end

      def build(opts = {})
        father.build(opts)
      end

      def build_hash(opts = {})
        father.build_hash(opts)
      end

      def build_brothers(num, opts = {}, &block)
        father.build_brothers(num, opts, &block)
      end
      
      def create_brothers(num, opts = {}, &block)
        father.create_brothers(num, opts, &block)
      end

      def scoped(attributes = {})
        father.scoped(attributes)
      end

      def scope(name)
        saved_attributes = @attributes
        @attributes = {}
        yield
        scopes[name] = @attributes
        singleton_class.send(:define_method, name) do
          father.send(name)
        end
      ensure
        @attributes = saved_attributes
      end

      def scopes
        @scopes ||= parent_class && parent_class.scopes.dup || {}
      end

      def model_class(klass=nil)
        if klass
          @model_class = klass
          return
        end

        @model_class ||= if class_name =~ /(.*)Famili$/ || class_name =~ /Famili::(.*)/
                           $1.split('::').inject(Object) do |mod, const|
                             mod.const_get(const)
                           end
                         end
      end
    end
  end
end

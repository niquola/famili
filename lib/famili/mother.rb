require 'date'
require 'famili/father'
require "famili/lazy_value"

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
      alias_method :class_name, :name

      delegate :build, :create, :build_brothers, :create_brothers, :build_hash, :scoped, to: :new_father

      def objects_sequence_number
        @sequence_number ||= 0
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
        @attributes ||= parent_class && parent_class.attributes.clone || {}
      end

      def field(method, value = nil, &block)
        block = -> { value } if value
        attributes[method] = block
      end

      def lazy(&block)
        Famili::LazyValue.new(&block)
      end

      def has(name, &block)
        attributes[name] = lazy do
          father = "#{model_class.reflect_on_association(name.to_sym).klass.name}Famili".constantize.new_father
          father = father.scoped(collect_attributes(&block)) if block_given?
          father
        end
      end

      def new_father
        Famili::Father.new(self.new, attributes)
      end

      def scope(name, &block)
        scopes[name] = collect_attributes(&block)
        singleton_class.send(:define_method, name) do
          new_father.send(name)
        end
      end

      def scopes
        @scopes ||= parent_class && parent_class.scopes.dup || {}
      end

      def model_class(klass = nil)
        if klass
          self.model_class = klass
          return
        end

        @model_class ||= if class_name =~ /(.*)Famili$/ || class_name =~ /Famili::(.*)/
                           $1.split('::').inject(Object) do |mod, const|
                             mod.const_get(const)
                           end
                         end
      end

      def model_class=(klass)
        @model_class = klass
      end

      protected

      def collect_attributes
        saved_attributes, @attributes = @attributes, {}
        yield
        @attributes
      ensure
        @attributes = saved_attributes
      end
    end
  end
end

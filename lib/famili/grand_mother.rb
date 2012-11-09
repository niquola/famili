require 'famili/father'
require "famili/lazy_value"

module Famili
  class GrandMother
    class_attribute :father_class
    self.father_class = Famili::Father

    delegate :build, :create, :build_brothers, :create_brothers, :build_hash, :scoped, to: :father

    def father
      @father ||= self.class.father_class.new(self, self.class.attributes)
    end

    def save(model)
    end

    def before_save(model)
    end

    def after_create(model)
    end

    class << self
      alias_method :class_name, :name

      delegate :build, :create, :build_brothers, :create_brothers, :build_hash, :scoped, to: :new

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
          mother = "#{model_class.reflect_on_association(name.to_sym).klass.name}Famili".constantize.new
          mother = mother.scoped(collect_attributes(&block)) if block_given?
          mother
        end
      end

      def trait(name, &block)
        attributes = collect_attributes(&block)
        scope(name) { scoped(attributes) }
      end

      def scope(name, &block)
        ensure_own_father_class.send(:define_method, name, &block)
        delegate name, to: :father
        singleton_class.delegate name, to: :new
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

      def ensure_own_father_class
        @father_class = self.father_class = Class.new(self.father_class) unless @father_class == father_class
        @father_class
      end

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
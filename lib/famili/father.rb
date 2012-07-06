require "famili/child"

module Famili
  class Father
    attr_reader :attributes
    attr_reader :mother

    def initialize(mother, attributes)
      @mother = mother
      @attributes = attributes
    end

    def build_hash(opts = {})
      attributes = build(opts).attributes.symbolize_keys
      attributes.delete(:updated_at)
      attributes.delete(:created_at)
      attributes
    end

    def build(opts = {})
      attributes = merge(opts)
      model = Famili::Child.new(@mother, attributes).born
      yield model if block_given?
      @mother.before_save(model)
      model
    end

    def create(opts = {}, &block)
      model = build(opts, &block)
      model.save!
      @mother.after_create(model)
      model
    end

    def produce_brothers(num, opts={}, init_block, &block)
      brothers = []
      if init_block && init_block.arity == 2
        num.times { |i| brothers << block.call(opts) { |o| init_block.call(o, i) } }
      else
        num.times { brothers << block.call(opts, &init_block) }
      end
      brothers
    end

    private_methods :produce_brothers

    def build_brothers(num, opts = {}, &block)
      produce_brothers(num, opts, block) { |brother_opts, &init_block| build(brother_opts, &init_block) }
    end

    def create_brothers(num, opts = {}, &block)
      produce_brothers(num, opts, block) { |brother_opts, &init_block| create(brother_opts, &init_block) }
    end

    def scoped(attributes = {})
      self.class.new(@mother, merge(attributes))
    end

    private

    def merge(attributes)
      self.attributes.merge(attributes)
    end
  end
end

require "famili/child"

module Famili
  class Father
    def initialize(mother, attributes)
      @mother = mother
      @attributes = attributes
    end
    
    def build_hash(opts = {})
      build(opts).attributes.symbolize_keys
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

    def build_brothers(num, opts = {}, &block)
      brothers = []
      num.times { brothers << build(opts, &block) }
      brothers
    end

    def create_brothers(num, opts = {}, &block)
      brothers = []
      num.times { brothers << create(opts, &block) }
      brothers
    end

    def scoped(attributes = {})
      Famili::Father.new(@mother, merge(attributes))
    end

    def method_missing(name, *args)
      if scope_attributes = @mother.class.scopes[name]
        scoped(scope_attributes)
      else
        super(name, *args)
      end
    end

    private

    def merge(attributes)
      @attributes.merge(attributes)
    end
  end
end
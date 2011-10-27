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
      @mother.before_save(model)
      model
    end

    def create(opts = {})
      model = build(opts)
      model.save!
      @mother.after_create(model)
      model
    end

    def method_missing(name, *args)
      if scope_attributes = @mother.class.scopes[name]
        Famili::Father.new(@mother, merge(scope_attributes))
      else
        super
      end
    end

    private

    def merge(attributes)
      @attributes.merge(attributes)
    end
  end
end
require 'date'
module  Famili

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
        field(:name,&block)
      end

      def method_missing(method,&block)
        return field(method,&block) if block_given?
        super
      end

      def attribures
        @attribures||=parent_class && parent_class.attribures.clone
        @attribures||=[]
        @attribures.uniq!
        @attribures
      end

      def field(method,&block)
        attribures<< method
        #puts "define_method #{method} #{self}"
        define_method(method,&block) if block_given?
      end

      def create(opts={})
        mother,model = _build(opts)
        model.save!
        mother.after_create(model)
        model
      end

      def build(opts={})
        _,model = _build(opts)
        model
      end

      def build_hash(opts={})
        _,model = _build(opts)
        model.attributes.dup.symbolize_keys!
      end

      if RUBY_VERSION.sub(/(\d+\.\d+).*/, "$1").to_f < 1.9
        def hash(opts={})
          warn "[DEPRECATION] `hash` is deprecated and not supported for Ruby 1.9. Please use `build_hash` instead."
        end
      end


      def _build(opts)
        mother = new
        model = model_class.new
        opts.symbolize_keys!
        passed_attrs = opts.keys  || []

        mother.instance_eval do
          singleton = class <<self;self;end;
          passed_attrs.each do |attr|
            value = opts[attr]
            if value.class == Proc
              singleton.send(:define_method,attr,&value)
            else
              singleton.send(:define_method,attr) do
                opts[attr]
              end
            end
          end
      end

      fields = ( passed_attrs + attribures).uniq
      fields.each do |attr|
        attr = attr.to_sym
        value = opts.key?(attr) ?  opts[attr] : mother.send(attr)
        model.send(:"#{attr}=",value)
      end
      mother.before_save(model)
      [mother,model]
    end

    private

    def model_class(klass=nil)
      if klass 
        @model_class = klass
        return
      end

      @model_class||= class_name.to_s.split('::')[1..-1].inject(Object) do |mod,const| 
        mod.const_get(const)
      end
    end
  end
end
end

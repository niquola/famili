module  Famili
  def before_save(model)
  end

  def after_create(model)
  end

  class Mother
    class << self
      alias :class_name :name

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
        field(:name,&block)
      end

      def method_missing(method,&block)
        field(method,&block)
      end

      def attribures
        @attribures||=parent_class && parent_class.attribures
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
        model.save
        mother.after_create(model)
        model
      end

      def build(opts={})
        mother,model = _build(opts)
        model
      end

      def hash
        mother,model = _build
        model.attribures
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

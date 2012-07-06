class Module
  def remove_possible_method(method)
    if method_defined?(method) || private_method_defined?(method)
      undef_method(method)
    end
  end
end

class Class
  def class_attribute(*attrs)
    attrs.each do |name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{name}() nil end
        def self.#{name}?() !!#{name} end

        def self.#{name}=(val)
          singleton_class.class_eval do
            remove_possible_method(:#{name})
            define_method(:#{name}) { val }
          end

          if singleton_class?
            class_eval do
              remove_possible_method(:#{name})
              def #{name}
                defined?(@#{name}) ? @#{name} : singleton_class.#{name}
              end
            end
          end
          val
        end
      RUBY
    end
  end

  private
  def singleton_class?
    ancestors.first != self
  end
end
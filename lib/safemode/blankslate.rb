module Safemode
  class Blankslate
    @@allow_instance_methods = ['class', 'methods', 'respond_to?', 'respond_to_missing?', 'to_s', 'instance_variable_get']
    @@allow_class_methods    = ['singleton_class?', 'methods', 'new', 'name', '<', 'ancestors', '==']  # < needed in Rails Object#subclasses_of
    if defined?(JRUBY_VERSION)
      # JRuby seems to silently fail to remove method_missing
      # (also see https://github.com/jruby/jruby/blob/9.1.7.0/core/src/main/java/org/jruby/RubyModule.java#L1109)
      @@allow_class_methods << 'method_missing'
      (@@allow_class_methods << ['singleton_method_undefined', 'singleton_method_added']).flatten! # needed for JRuby support
    end

    silently { undef_methods(*instance_methods.map(&:to_s) - @@allow_instance_methods) }
    class << self
      silently { undef_methods(*instance_methods.map(&:to_s) - @@allow_class_methods) }

      def method_added(name) end # ActiveSupport needs this

      def inherited(subclass)
        subclass.init_allowed_methods(@allowed_instance_methods, @allowed_class_methods)
      end

      def init_allowed_methods(allowed_instance_methods, allowed_class_methods)
        @allowed_instance_methods = allowed_instance_methods
        @allowed_class_methods = allowed_class_methods
      end

      def allowed_instance_methods
        @allowed_instance_methods ||= []
      end
      alias_method :allowed_methods, :allowed_instance_methods

      def allowed_class_methods
        @allowed_class_methods ||= []
      end

      def allow_instance_method(*names)
        @allowed_instance_methods = allowed_instance_methods + names.map{|name| name.to_s}
        @allowed_instance_methods.uniq!
      end
      alias_method :allow, :allow_instance_method

      def allow_class_method(*names)
        @allowed_class_methods = allowed_class_methods + names.map{|name| name.to_s}
        @allowed_class_methods.uniq!
      end

      def allowed_instance_method?(name)
        allowed_instance_methods.include? name.to_s
      end
      alias_method :allowed?, :allowed_instance_method?

      def allowed_class_method?(name)
        allowed_class_methods.include? name.to_s
      end
    end
  end
end

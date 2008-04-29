require 'safemode'
require 'haml/safemode'

module ActionView
  module TemplateHandlers
    class SafeHaml < TemplateHandler
      include SafemodeHandler
      
      def self.line_offset
      3
      end

      def compile(template)
        options = Haml::Template.options.dup
        haml = Haml::Engine.new template, options
        methods = delegate_methods + ActionController::Routing::Routes.named_routes.helpers
        haml.precompile_for_safemode ignore_assigns, methods
      end
    end
  end
end
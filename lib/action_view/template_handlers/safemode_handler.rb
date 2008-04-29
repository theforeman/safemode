module ActionView
  module TemplateHandlers
    module SafemodeHandler      
      def delegate_methods
        [ :render, :params, :flash ] + helper_methods
      end

      def helper_methods
        @view.class.included_modules.collect {|m| m.instance_methods(false) }.flatten.map(&:to_sym)
      end

      def ignore_assigns
        [ "_cookies", "_flash", "_headers", "_params", "_request", "_response", 
          "_session", "before_filter_chain_aborted", "ignore_missing_templates", 
          "logger", "request_origin", "template", "template_class", "url", 
          "variables_added", "view_paths" ]
      end
    end
  end
end
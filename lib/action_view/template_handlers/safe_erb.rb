require 'safemode'
require 'erb'

module ActionView
  module TemplateHandlers
    class SafeErb < TemplateHandler
      include SafemodeHandler
      
      def self.line_offset
        0
      end
      
      def compile(template)
        code = ::ERB.new(template, nil, @view.erb_trim_mode).src
        code.gsub!('\\','\\\\\\') # backslashes would disappear in compile_template/modul_eval, so we escape them

        # wow, this sucks. ruby gets totally confused about backtrace line numbers
        # when the line_offset is greater than x (like 5?) so that Rails' template
        # error rewriting breaks. thus, we have to reduce the code to no more than
        # one line before the actually executed template code starts

        preamble =  "assigns = @template.assigns.reject{|key, value| #{ignore_assigns.inspect}.include?(key) }
                     methods = #{delegate_methods.inspect} + ActionController::Routing::Routes.named_routes.helpers;".gsub("\n", ';')
                    
        postamble = "box = Safemode::Box.new(self, methods)
                     box.eval(code, assigns, local_assigns, &lambda{ yield })".gsub("\n", ';')
        
        preamble + "code = %Q(#{code});" + postamble
      end
    end
  end
end

# frozen_string_literal: true

module Safemode
  # Preserve distinctions that Ruby2Ruby can ignore, but jailing cannot:
  # implicit local variables are not method calls, and pattern | is not or.
  class RubyParser < Prism::Translation::RubyParser
    class Compiler < Prism::Translation::RubyParser.const_get(:Compiler)
      def visit_it_local_variable_read_node(node)
        s(node, :lvar, :it)
      end

      def visit_local_variable_read_node(node)
        s(node, :lvar, node.name)
      end

      def visit_alternation_pattern_node(node)
        s(node, :pattern_or, visit(node.left), visit(node.right))
      end

      private

      def copy_compiler(in_def: self.in_def, in_pattern: self.in_pattern)
        self.class.new(file, in_def: in_def, in_pattern: in_pattern)
      end
    end
    private_constant :Compiler

    private

    def translate(result, filepath)
      return super if result.failure?

      result.attach_comments!
      result.value.accept(Compiler.new(filepath))
    end
  end
end

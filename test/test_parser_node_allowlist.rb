# frozen_string_literal: true
require_relative 'test_helper'

class TestParserNodeAllowlist < Test::Unit::TestCase
  def test_new_dependency_node_handlers_are_not_implicitly_trusted
    parser = Class.new(Safemode::Parser) do
      def process_unreviewed_node(exp)
        '42'
      end
    end
    assert_raise(Safemode::SecurityError) { parser.new.process(Sexp.new(:unreviewed_node)) }
  end
end

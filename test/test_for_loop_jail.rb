# frozen_string_literal: true
require_relative 'test_helper'

class TestForLoopJail < Test::Unit::TestCase
  class Host
    attr_reader :calls

    def initialize
      @calls = []
    end

    def each
      @calls << :each
      yield 'secret'
    end
  end

  def test_for_loop_checks_each_permission
    host = Host.new
    assert_raise(Safemode::NoMethodError) do
      Safemode::Box.new.eval('for x in @host; x; end', host: host)
    end
    assert_empty host.calls
    assert_equal 3, Safemode::Box.new.eval('sum = 0; for x in [1, 2]; sum += x; end; sum')
    assert_equal 2, Safemode::Box.new.eval('for x in [1, 2]; end; x')
  end
end

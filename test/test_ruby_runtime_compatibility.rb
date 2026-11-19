# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'test_helper')

class TestRubyRuntimeCompatibility < Test::Unit::TestCase
  class Receiver
    attr_reader :calls

    def initialize
      @calls = []
    end

    def arguments(*args, **kwargs)
      [args, kwargs]
    end

    private

    def instance_variables_to_inspect
      @calls << :inspect_hook
      []
    end

    class Jail < Safemode::Jail
      allow :arguments, :inspect
    end
  end

  def setup
    @box = Safemode::Box.new
    @receiver = Receiver.new
  end

  def test_nil_splats_match_the_running_ruby
    ['@receiver.arguments(*nil)', '@receiver.arguments(**nil)',
     '@receiver.arguments(1, *nil, a: 2, **nil)'].each do |code|
      begin
        expected = instance_eval(code)
      rescue TypeError => error
        assert_raise(error.class) { @box.eval(code, receiver: @receiver) }
      else
        assert_equal expected, @box.eval(code, receiver: @receiver)
      end
    end
  end

  def test_leading_logical_operators_preserve_method_jailing
    assert_equal false, @box.eval("true\n&& false")
    assert_equal true, @box.eval("false\n|| true")
    assert_equal false, @box.eval("true\nand false")
    assert_equal true, @box.eval("false\nor true")
    assert_raise(Safemode::NoMethodError) do
      @box.eval("true\n&& @article.instance_variable_get(:@source)", article: Article.new)
    end
  end

  def test_new_core_methods_are_not_implicitly_allowed
    ['[1].fetch_values(0)', '[1].rfind { |n| n == 1 }', '"a".append_as_bytes("b")'].each do |code|
      assert_raise(Safemode::NoMethodError) { @box.eval(code) }
    end
  end

  def test_new_core_constants_remain_blocked
    ['Ruby::Box', 'Ractor::Port', 'Set[1]', 'Pathname.new(".")'].each do |code|
      assert_raise(Safemode::SecurityError) { @box.eval(code) }
    end
  end

  def test_binding_introspection_remains_blocked
    ['@value.local_variables', '@value.implicit_parameters'].each do |code|
      assert_raise(Safemode::NoMethodError) { @box.eval(code, value: binding) }
    end
  end

  def test_string_buffers_and_literal_freezing
    assert_equal 'ab', @box.eval('s = "a"; s << "b"; s')
    assert_equal 'auditx', @box.eval('s = :audit.to_s; s << "x"; s')
    assert_predicate @box.eval('"literal".freeze'), :frozen?
    source = String.new('host value')
    assert_raise(Safemode::NoMethodError) { @box.eval('@value.freeze', value: source) }
    assert_false source.frozen?
    assert_equal 'Hi WORLD', @box.eval(ERB.new('Hi <%= @name.upcase %>').src, name: 'world')
  end

  def test_changed_core_results_match_the_running_ruby
    assert_equal({a: 1}.inspect, @box.eval('{a: 1}.inspect'))
    assert_equal '1.E-1'.to_f, @box.eval('"1.E-1".to_f')
  end

  def test_strip_selectors_match_the_running_ruby
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.0')
      assert_equal 'abc', @box.eval('"**abc**".strip("*")')
    else
      assert_raise(ArgumentError) { @box.eval('"**abc**".strip("*")') }
    end
  end

  def test_inspect_hook_is_not_directly_exposed
    @box.eval('@receiver.inspect', receiver: @receiver)
    expected_calls = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.0') ? [:inspect_hook] : []
    assert_equal expected_calls, @receiver.calls
    assert_raise(Safemode::NoMethodError) do
      @box.eval('@receiver.instance_variables_to_inspect', receiver: @receiver)
    end
  end
end

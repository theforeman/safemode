# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'test_helper')

class TestSafemodeEval < Test::Unit::TestCase
  include TestHelper

  def setup
    @box = Safemode::Box.new
    @locals = { :article => Article.new }
    @assigns = { :article => Article.new }
  end

  def test_some_stuff_that_should_work
    ['"test".upcase', '10.succ', '10.times{}', '[1,2,3].each{|a| a + 1}',
     'true ? 1 : 0', 'a = 1', 'if "a" != "b"; "true"; end',
     'if "a" == "b"; "true"; end', 'String.new'].each do |code|
      assert_nothing_raised{ @box.eval code }
    end
  end

   def test_safe_navigation_operator
     assert_equal "1", @box.eval('x = 1; x&.to_s')
   end

  def test_unary_operators_on_instances_of_boolean_vars
    assert @box.eval('not false')
    assert @box.eval('!false')
    assert !@box.eval('not true')
    assert !@box.eval('!true')
  end

  def test_false_class_ops
    assert !@box.eval('false ^ false')
    assert !@box.eval('false & false')
    assert !@box.eval('false && false')
    assert !@box.eval('false and false')
    assert !@box.eval('false | false')
    assert !@box.eval('false || false')
    assert !@box.eval('false or false')
    assert @box.eval('false == false')
    assert @box.eval('false != true')
  end

  def test_true_class_ops
    assert !@box.eval('true ^ true')
    assert @box.eval('true & true')
    assert @box.eval('true && true')
    assert @box.eval('true and true')
    assert @box.eval('true | true')
    assert @box.eval('true || true')
    assert @box.eval('true or true')
    assert @box.eval('true == true')
    assert @box.eval('true != false')
  end

  def test_should_turn_assigns_to_jails
    assert_raise_no_method "@article.system", @assigns
  end

  def test_should_turn_locals_to_jails
    assert_raise(Safemode::NoMethodError){ @box.eval "article.system", {}, @locals }
  end

  def test_should_allow_method_access_on_assigns
    assert_nothing_raised{ @box.eval "@article.title", @assigns }
  end

  def test_should_allow_method_access_on_locals
    assert_nothing_raised{ @box.eval("article.title", {}, @locals) }
  end

  def test_should_not_raise_on_if_using_return_values
    assert_nothing_raised{ @box.eval "if @article.is_article? then 1 end", @assigns }
  end

  def test_should_work_with_if_using_return_values
    assert_equal @box.eval("if @article.is_article? then 1 end", @assigns), 1
  end

  def test__FILE__should_not_render_filename
    assert_equal '(string)', @box.eval("__FILE__")
  end

  def test_interpolated_xstr_should_raise_security
    assert_raise_security '"#{`ls -a`}"'
  end

  def test_should_not_allow_access_to_bind
    assert_raise_security "self.bind('an arg')"
  end

  def test_sending_of_kwargs_works
    assert @box.eval("@article.method_with_kwargs(a_keyword: true)", @assigns)
  end

  def test_pattern_matching_with_literal
    assert_equal "matched", @box.eval('case 1; in 1; "matched"; in 2; "nope"; end')
  end

  def test_pattern_matching_with_array_destructuring
    assert_equal 1, @box.eval('case [1, 2, 3]; in [a, b, c]; a; end')
  end

  def test_pattern_matching_with_hash_destructuring
    assert_equal 1, @box.eval('case({a: 1, b: 2}); in {a:}; a; end')
  end

  def test_pattern_matching_with_assign
    assert_equal "two", @box.eval('case @val; in 1; "one"; in 2; "two"; end', { val: 2 })
  end

  def test_pattern_matching_with_find_pattern
    assert_equal "found", @box.eval('case [1, 2, 3]; in [*, 2, *]; "found"; end')
  end

  def test_pattern_matching_with_pin_operator
    assert_equal "matched", @box.eval('y = 1; case 1; in ^y; "matched"; end')
  end

  def test_pattern_matching_with_multiple_clauses
    assert_equal "second", @box.eval('case [3, 4]; in [1, 2]; "first"; in [3, 4]; "second"; end')
  end

  def test_pattern_matching_no_match_returns_nil
    assert_nil @box.eval('case 3; in 1; "one"; in 2; "two"; else; nil; end')
  end

  def test_pattern_matching_with_if_guard
    assert_equal "positive", @box.eval('case 1; in x if x > 0; "positive"; end')
  end

  def test_pattern_matching_with_unless_guard
    assert_equal "not negative", @box.eval('case 1; in x unless x < 0; "not negative"; end')
  end

  def test_pattern_matching_guard_no_match
    assert_nil @box.eval('case 1; in x if x < 0; "negative"; else; nil; end')
  end

  def test_pattern_matching_guard_with_array_pattern
    assert_equal "yes", @box.eval('case [1, 2]; in [a, b] if a > 0; "yes"; end')
  end

  def test_pattern_matching_guard_with_hash_pattern
    assert_equal "alice", @box.eval('case({name: "alice"}); in {name:} if name.start_with?("a"); name; end')
  end

  def test_rightward_assignment
    assert_equal 1, @box.eval('[1, 2] => [a, b]; a')
  end

  def test_pattern_matching_with_jailed_hash
    assert_equal "an article title", @box.eval('case @data; in {title:}; title; end', { data: { title: "an article title" } })
  end

  def test_hash_shorthand
    # TODO: Remove the check once Ruby 3.1 is the minimum
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1')
      assert_equal({ a: 1, b: 2 }, @box.eval('a = 1; b = 2; { a:, b: }'))
    end
  end

  def test_endless_range
    assert_equal [3, 4, 5], @box.eval('[1,2,3,4,5][2..]')
  end

  def test_beginless_range
    assert_equal [1, 2, 3], @box.eval('[1,2,3,4,5][..2]')
  end

  # attrasgn (@article.status = val) is blocked at parse time
  def test_attrasgn_is_blocked
    assert_raise(Safemode::SecurityError) { @box.eval('@article.status = "new_value"', @assigns) }
  end

  def test_safe_attrasgn_is_blocked
    assert_raise(Safemode::SecurityError) { @box.eval('@article&.status = "new_value"', @assigns) }
  end

  # op_asgn2 (@article.status ||= val) is NOT blocked at parse time.
  # NOTE: .to_jail is not inserted on the receiver, so the setter is called
  # directly on the real object, bypassing the Jail whitelist.
  def test_op_asgn2_bypasses_jail
    article = Article.new
    assert_nil article.status
    @box.eval('@article.status ||= "new_value"', { article: article })
    assert_equal "new_value", article.status
  end

  def test_safe_op_asgn2_bypasses_jail
    article = Article.new
    assert_nil article.status
    @box.eval('@article&.status ||= "new_value"', { article: article })
    assert_equal "new_value", article.status
  end

  def test_freeze_on_jailed_object_is_blocked
    assert_raise(Safemode::NoMethodError) do
      @box.eval('@arr.freeze', { arr: [1, 2, 3] })
    end
  end

  def test_lambda_is_blocked
    assert_raise(Safemode::SecurityError) { @box.eval('-> { 1 }') }
  end

  def test_sending_to_method_missing
    assert_raise_with_message(Safemode::NoMethodError, /#no_such_method/) do
      @box.eval("@article.no_such_method('arg', key: 'value')", @assigns)
    end
  end

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
    def test_pattern_matching_with_data_subclass
      point_class = Data.define(:x, :y)
      point = point_class.new(x: 10, y: 20)
      assert_equal 10, @box.eval('case @point; in {x:}; x; end', { point: point })
    end

    def test_data_subclass_inherits_data_jail
      point_class = Data.define(:x, :y)
      point = point_class.new(x: 10, y: 20)
      assert_equal [:x, :y], @box.eval('@point.members', { point: point })
      assert_equal [10, 20], @box.eval('@point.deconstruct', { point: point })
      assert_equal({ x: 10 }, @box.eval('@point.deconstruct_keys([:x])', { point: point }))
    end

    def test_data_subclass_jail_blocks_non_whitelisted_methods
      point_class = Data.define(:x, :y)
      point = point_class.new(x: 10, y: 20)
      assert_raise(Safemode::NoMethodError) { @box.eval('@point.instance_variables', { point: point }) }
    end
  end

  TestHelper.no_method_error_raising_calls.each do |call|
    class_eval %Q(
      def test_calling_#{call.gsub(/[\W]/, '_')}_should_raise_no_method
        assert_raise_no_method "#{call.gsub('"', '\\\\"')}", @assigns, @locals
      end
    )
  end

  TestHelper.security_error_raising_calls.each do |call|
    class_eval %Q(
      def test_calling_#{call.gsub(/[\W]/, '_')}_should_raise_security
        assert_raise_security "#{call.gsub('"', '\\\\"')}", @assigns, @locals
      end
    )
  end

end

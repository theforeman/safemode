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
        
  TestHelper.no_method_error_raising_calls.each do |call|
    call.gsub!('"', '\\\\"')
    class_eval %Q(
      def test_calling_#{call.gsub(/[\W]/, '_')}_should_raise_no_method
        assert_raise_no_method "#{call}", @assigns, @locals
      end
    )
  end

  TestHelper.security_error_raising_calls.each do |call|
    call.gsub!('"', '\\\\"')
    class_eval %Q(
      def test_calling_#{call.gsub(/[\W]/, '_')}_should_raise_security
        assert_raise_security "#{call}", @assigns, @locals
      end
    )
  end  

end

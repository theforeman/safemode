# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'test_helper')

class TestJail < Test::Unit::TestCase
  def setup
    @box = Safemode::Box.new
    @article = Article.new.to_jail
    @comment = @article.comments.first
    @comment_class = Comment.to_jail
    @extended_comment = ExtendedComment.new(@article).to_jail
  end

  def test_explicitly_allowed_instance_methods_should_be_accessible
    assert_nothing_raised { @article.title }
  end

  def test_explicitly_allowed_class_methods_should_be_accessible
    assert_nothing_raised { @comment_class.all(1) }
  end

  def test_jail_instance_methods_should_be_accessible
    assert_nothing_raised { @article.author_name }
  end

  def test_sending_to_jail_to_an_object_should_return_a_jail
    assert_equal "Article::Jail", @article.class.name
  end

  def test_sending_of_kwargs_works
    assert @article.method_with_kwargs(a_keyword: true)
  end

  def test_sending_to_method_missing
    assert_raise_with_message(Safemode::NoMethodError, /#no_such_method/) do
      @article.no_such_method('arg', key: 'value')
    end
  end

  def test_jail_instances_should_have_limited_methods
    expected = ["class", "method_missing", "methods", "respond_to?", "to_jail", "to_s", "instance_variable_get"]
    objects.each do |object|
      assert_equal expected.sort, reject_pretty_methods(object.to_jail.methods.map(&:to_s).sort)
    end
  end

  def test_jail_classes_should_have_limited_methods
    expected = ["new", "methods", "name", "inherited", "method_added",
                "allow", "allowed?", "allowed_methods", "init_allowed_methods",
                "allow_instance_method", "allow_class_method", "allowed_instance_method?",
                "allowed_class_method?", "allowed_instance_methods", "allowed_class_methods",
                "<", # < needed in Rails Object#subclasses_of
                "ancestors", "==", # ancestors and == needed in Rails::Generator::Spec#lookup_class
                "singleton_class?" ]

    if defined?(JRUBY_VERSION)
      (expected << ['method_missing', 'singleton_method_undefined', 'singleton_method_added']).flatten!  # needed for running under jruby
    end

    objects.each do |object|
      assert_equal expected.sort, reject_pretty_methods(object.to_jail.class.methods.map(&:to_s).sort)
    end
  end

  def test_allowed_methods_should_be_propagated_to_subclasses
    assert_equal Article::Jail.allowed_methods, Article::ExtendedJail.allowed_methods
  end

  def test_respond_to_works_correctly
    assert @article.respond_to?(:title)
    assert !@article.respond_to?(:bogus)
  end

  def test_methodcall_comment
    assert_equal "comment #{@comment.object_id}", @comment.text
  end

  def test_methodcall_extended_comment
    assert_equal "extended comment #{@extended_comment.object_id}", @extended_comment.extended_text
  end

    def test_it_keyword_is_jailed_in_block
    jailed = Safemode::Parser.jail('[1,2,3].map { it }')
    assert_match(/to_jail\.it/, jailed,
      "`it` should be jailed via to_jail")
  end

  def test_numbered_param_is_jailed_in_block
    jailed = Safemode::Parser.jail('[1,2,3].map { _1 }')
    assert_match(/to_jail\._1/, jailed,
      "`_1` should be jailed via to_jail")
  end

  def test_it_in_block_does_not_bypass_jail
    assert_raise(Safemode::SecurityError) do
      @box.eval('[1,2,3].map { it }')
    end
  end

  def test_numbered_param_in_block_does_not_bypass_jail
    assert_raise(Safemode::SecurityError) do
      @box.eval('[1,2,3].map { _1 }')
    end
  end

    def test_pattern_match_body_is_jailed
    assert_raise(Safemode::SecurityError) do
      @box.eval('case 1; in x; system("whoami"); end')
    end
  end

  def test_pattern_match_subject_is_jailed
    assert_raise(Safemode::SecurityError) do
      @box.eval('case `whoami`; in x; x; end')
    end
  end

  def test_pattern_match_deconstruct_on_array_jails_bound_var
    assert_raise(Safemode::SecurityError) do
      @box.eval('case [1, 2, 3]; in [x, *]; x; end')
    end
  end

  def test_pattern_match_bound_variable_is_jailed_in_body
    assert_raise(Safemode::SecurityError) do
      @box.eval('case 1; in x; x; end')
    end
  end

  def test_pattern_match_array_bound_variable_is_jailed
    assert_raise(Safemode::SecurityError) do
      @box.eval('case [1, 2]; in [x, y]; x; end')
    end
  end

  def test_pattern_match_hash_bound_variable_is_jailed
    assert_raise(Safemode::SecurityError) do
      @box.eval('case {a: 1}; in {a: x}; x; end')
    end
  end

  def test_rightward_assignment_bound_variable_is_jailed
    assert_raise(Safemode::SecurityError) do
      @box.eval('1 => x; x')
    end
  end
  
  def test_parser_jails_calls_inside_pattern_match_body
    jailed = Safemode::Parser.jail('case 1; in x; x.to_s; end')
    assert_match(/to_jail/, jailed,
      "method calls in pattern match body should be jailed")
  end


  private

  def objects
    [[], {}, 1..2, "a", :a, Time.now, 1, 1.0, nil, false, true, Comment]
  end

  def reject_pretty_methods(methods)
    methods.reject{ |method| method =~ /^pretty_/ }
  end

end

# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'test_helper')

class TestSafemodeParser < Test::Unit::TestCase
  def test_vcall_should_be_jailed
    assert_jailed 'to_jail.a.to_jail.class', 'a.class'
  end

  def test_call_should_be_jailed
    assert_jailed '(1.to_jail + 1).to_jail.class', '(1 + 1).class'
  end

  def test_estr_should_be_jailed
    assert_jailed '"#{1.to_jail.class}"', '"#{1.class}"'
  end

  def test_if_should_be_usable_for_erb
    assert_jailed "if true then\n 1\nend", "if true\n 1\n end"
  end

  def test_if_else_should_be_usable_for_erb
    assert_jailed "if true then\n 1\n else\n2\nend", "if true\n 1\n else\n2\n end"
  end

  def test_ternary_should_be_usable_for_erb
    assert_jailed "if true then\n 1\n else\n2\nend", "true ? 1 : 2"
  end

  def test_call_with_shorthand
    unsafe = <<~UNSAFE
      a_keyword = true
      @article.method_with_kwargs(a_keyword:)
    UNSAFE
    jailed = <<~JAILED
      a_keyword = true
      @article.to_jail.method_with_kwargs(a_keyword:)
    JAILED
    assert_jailed jailed, unsafe
  end

  def test_call_with_complex_args
    unsafe = "kwargs = { b_keyword: false }; @article.method_with_kwargs('positional', a_keyword: true, **kwargs)"
    jailed = "kwargs = { :b_keyword => false }\n@article.to_jail.method_with_kwargs(\"positional\", :a_keyword => true, **kwargs)\n"
    assert_jailed jailed, unsafe
  end

  def test_safe_call_simple
    assert_jailed '@article&.to_jail&.method', '@article&.method'
  end

  def test_safe_call_with_complex_args
    unsafe = "kwargs = { b_keyword: false }; @article&.method_with_kwargs('positional', a_keyword: true, **kwargs)"
    jailed = "kwargs = { :b_keyword => false }\n@article&.to_jail&.method_with_kwargs(\"positional\", :a_keyword => true, **kwargs)\n"
    assert_jailed jailed, unsafe
  end

  def test_output_buffer_should_be_assignable
    assert_nothing_raised do
      jail('@output_buffer = ""')
    end
  end

  def test_block_pass_is_disabled
    assert_raise Safemode::SecurityError do
      jail('[].each(&:delete)')
    end
  end

  def test_safe_attrasgn_is_disabled
    assert_raise Safemode::SecurityError do
      jail('@article&.title = "new_value"')
    end
  end

  def test_safe_op_asgn2_is_allowed
    assert_nothing_raised do
      jail('@article&.title ||= "new_value"')
    end
  end

  def test_lambda_is_disabled
    assert_raise Safemode::SecurityError do
      jail('-> { 1 }')
    end
  end

  def test_case_in_with_literal
    jailed = jail("case x; in 1; \"one\"; in 2; \"two\"; end")
    assert_match(/in 1 then/, jailed)
    assert_match(/in 2 then/, jailed)
    assert_match(/to_jail\.x/, jailed)
  end

  def test_case_in_with_array_pattern
    jailed = jail("case x; in [a, b]; a; end")
    assert_match(/in \[a, b\] then/, jailed)
    assert_no_match(/\^a/, jailed)
  end

  def test_case_in_with_hash_pattern
    jailed = jail("case x; in {name:}; name; end")
    assert_match(/in \{ name: \} then/, jailed)
    assert_no_match(/\^name/, jailed)
  end

  def test_case_in_with_find_pattern
    jailed = jail("case x; in [*, 2, *]; \"found\"; end")
    assert_match(/in \[\*, 2, \*\] then/, jailed)
  end

  def test_case_in_pin_operator
    jailed = jail("y = 1; case x; in ^y; true; end")
    assert_match(/in \^y then/, jailed)
  end

  def test_case_in_pin_expression
    return if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("3.1")

    jailed = jail("case 2; in ^(1 + 1); true; end")
    assert_match(/in \^\(\(1\.to_jail \+ 1\)\) then/, jailed)
  end

  def test_case_in_body_does_not_pin_variables
    jailed = jail("case x; in [a, b]; a; end")
    lines = jailed.lines
    body_start = lines.index { |l| l.match?(/^in \[/) } + 1
    lines[body_start..].each { |line| assert_no_match(/\^[a-z]/, line) }
  end

  def test_case_in_multiple_clauses
    jailed = jail("case x; in [a, b]; a; in {c:}; c; end")
    assert_match(/in \[a, b\] then/, jailed)
    assert_match(/in \{ c: \} then/, jailed)
  end

  def test_case_in_with_if_guard
    jailed = jail("case x; in 1 if true; \"matched\"; end")
    assert_match(/in 1 if true then/, jailed)
  end

  def test_case_in_with_unless_guard
    jailed = jail("case x; in 1 unless false; \"matched\"; end")
    assert_match(/in 1 unless false then/, jailed)
  end

  def test_case_in_guard_does_not_pin_variables
    jailed = jail("case x; in [a, b] if a; a; end")
    guard_line = jailed.lines.find { |l| l.match?(/^in \[/) }
    assert_match(/if a then/, guard_line)
    assert_no_match(/\^a/, guard_line)
  end

  def test_case_in_guard_jails_method_calls
    jailed = jail('case x; in {name: n} if n.start_with?("a"); n; end')
    assert_match(/if n\.to_jail\.start_with\?/, jailed)
  end

  def test_rightward_assignment
    jailed = jail("x => a")
    assert_match(/case to_jail\.x/, jailed)
    assert_match(/in a then/, jailed)
  end

  def test_hash_shorthand_in_literal
    jailed = jail("a = 1; b = 2; { a:, b: }")
    assert_match(/a:,/, jailed)
  end

  def test_endless_range
    assert_jailed "(1..)", "(1..)"
  end

  def test_beginless_range
    assert_jailed "(..5)", "(..5)"
  end

private

  def assert_jailed(expected, code)
    assert_equal expected.gsub(' ', ''), jail(code).gsub(' ', '')
  end

  def jail(code)
    Safemode::Parser.jail(code)
  end
end


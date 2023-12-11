module Safemode
  class Parser < Ruby2Ruby
    # @@parser = defined?(RubyParser) ? 'RubyParser' : 'ParseTree'
    @@parser = 'RubyParser'

    class << self
      def jail(code, allowed_fcalls = [])
        @@allowed_fcalls = allowed_fcalls
        tree = parse code
        self.new.process(tree)
      end

      def parse(code)
        case @@parser
        # when 'ParseTree'
        #   ParseTree.translate(code)
        when 'RubyParser'
          RubyParser.new.parse(code)
        else
          raise "unknown parser #{@@parser}"
        end
      end

      def parser=(parser)
        @@parser = parser
      end
    end

    def jail(str, parentheses = false, safe_call: false)
      str = if str
              dot = safe_call ? "&." : "."
              parentheses ? "(#{str})#{dot}" : "#{str}#{dot}"
            end
      "#{str}to_jail"
    end

    # split up #process_call. see below ...
    def process_call(exp, safe_call = false)
      exp.shift # remove ":call" symbol
      receiver = jail(process_call_receiver(exp), safe_call: safe_call)
      name = exp.shift
      args = process_call_args(exp)

      process_call_code(receiver, name, args, safe_call)
    end

    def process_fcall(exp)
      # using haml we probably never arrive here because :lasgn'ed :fcalls
      # somehow seem to change to :calls somewhere during processing
      # unless @@allowed_fcalls.include?(exp.first)
      #   code = Ruby2Ruby.new.process([:fcall, exp[1], exp[2]]) # wtf ...
      #   raise_security_error(exp.first, code)
      # end
      "to_jail.#{super}"
    end

    def process_vcall(exp)
      # unless @@allowed_fcalls.include?(exp.first)
      #   code = Ruby2Ruby.new.process([:fcall, exp[1], exp[2]]) # wtf ...
      #   raise_security_error(exp.first, code)
      # end
      name = exp[1]
      exp.clear
      "to_jail.#{name}"
    end

    def process_iasgn(exp)
      code = super
      if code != '@output_buffer = ""'
        raise_security_error(:iasgn, code)
      else
        code
      end
    end

    # see http://www.namikilab.tuat.ac.jp/~sasada/prog/rubynodes/nodes.html

    allowed =    [ :call, :vcall, :evstr,
                   :lvar, :dvar, :ivar, :lasgn, :masgn, :dasgn, :dasgn_curr,
                   :lit, :str, :dstr, :dsym, :nil, :true, :false,
                   :array, :zarray, :hash, :dot2, :dot3, :flip2, :flip3,
                   :if, :case, :when, :while, :until, :iter, :for, :break, :next, :yield,
                   :and, :or, :not,
                   :iasgn, # iasgn is sometimes allowed
                   # not sure about self ...
                   :self,
                   # :args is now used for block parameters
                   :args,
                   # :colon2 is used for module constants
                   :colon2,
                   # unnecessarily advanced?
                   :argscat, :argspush, :splat,
                   :op_asgn1, :op_asgn2, :op_asgn_and, :op_asgn_or,
                   # needed for haml
                   :block ]

    disallowed = [ # :self,  # self doesn't seem to be needed for vcalls?
                   # see below for :const handling
                   :defn, :defs, :alias, :valias, :undef, :class, :attrset,
                   :module, :sclass, :colon3,
                   :fbody, :scope, :block_arg, :postexe,
                   :redo, :retry, :begin, :rescue, :resbody, :ensure,
                   :defined, :super, :zsuper, :return,
                   :dmethod, :bmethod, :to_ary, :svalue, :match,
                   :attrasgn, :cdecl, :cvasgn, :cvdecl, :cvar, :gvar, :gasgn,
                   :xstr, :dxstr,
                   # not sure how secure ruby regexp is, so leave it out for now
                   :dregx, :dregx_once, :match2, :match3, :nth_ref, :back_ref,
                   # block_pass represents &:method, which would bypass the whitelist e.g. by array.each(&:destroy)
                   # at this point we don't know the receiver so we rather disable it completely,
                   # use array.each { |item| item.destroy } instead
                   :block_pass ]

    # SexpProcessor bails when we overwrite these ... but they are listed as
    # "internal nodes that you can't get to" in sexp_processor.rb
    # :ifunc, :method, :last, :opt_n, :cfunc, :newline, :alloca, :memo, :cref

    disallowed.each do |name|
      define_method "process_#{name}" do |arg|
        code = super(arg)
        raise_security_error(name, code)
      end
    end

    def process_const(arg)
      sexp_type = arg.sexp_body.sexp_type # constants are encoded as: "s(:const, :Encoding)"
      if sexp_type == :Encoding
        # handling of Encoding constants.
        # Note: ruby_parser evaluates __ENCODING__ to s(:colon2, s(:const, :Encoding), :UTF_8)
        "#{super(arg).gsub('-', '_')}"
      elsif sexp_type == :String
        # Allow String.new as used in ERB in Ruby 2.4+ to create a string buffer
        super(arg).to_s
      else
        raise_security_error("constant", super(arg))
      end
    end

    def raise_security_error(type, info)
      raise Safemode::SecurityError.new(type, info)
    end

    # split up Ruby2Ruby#process_call monster method so we can hook into it
    # in a more readable manner

    def process_call_receiver(exp)
      receiver_node_type = exp.first.nil? ? nil : exp.first.first
      receiver = process exp.shift
      receiver = "(#{receiver})" if
        Ruby2Ruby::ASSIGN_NODES.include? receiver_node_type
      receiver
    end

    def process_call_args(exp)
      args = []
      while not exp.empty? do
        args_exp = exp.shift
        if args_exp && args_exp.first == :array # FIX
          processed = "#{process(args_exp)[1..-2]}"
        else
          processed = process args_exp
        end
        args << processed unless (processed.nil? or processed.empty?)
      end
      args
    end

    def process_call_code(receiver, name, args, safe_call)
      case name
      when *BINARY then
        if safe_call
          "#{receiver}&.#{name}(#{args.join(", ")})"
        elsif args.length > 1
          "#{receiver}.#{name}(#{args.join(", ")})"
        else
          "(#{receiver} #{name} #{args.join(", ")})"
        end
      when :[] then
        receiver ||= "self"
        "#{receiver}[#{args.join(", ")}]"
      when :[]= then
        receiver ||= "self"
        rhs = args.pop
        "#{receiver}[#{args.join(", ")}] = #{rhs}"
      when :"!" then
        "(not #{receiver})"
      when :"-@" then
        "-#{receiver}"
      when :"+@" then
        "+#{receiver}"
      else
        args     = nil                    if args.empty?
        args     = "(#{args.join(", ")})" if args
        receiver = "#{receiver}."         if receiver and not safe_call
        receiver = "#{receiver}&."        if receiver and safe_call

        "#{receiver}#{name}#{args}"
      end
    end

    # Ruby2Ruby process_if rewrites if and unless statements in a way that
    # makes the result unusable for evaluation in, e.g. ERB which appends a
    # call to to_s when using <%= %> tags. We'd need to either enclose the
    # result from process_if into parentheses like (1 if true) and
    # (true ? (1) : (2)) or just use the plain if-then-else-end syntax (so
    # that ERB can safely append to_s to the resulting block).

    def process_if(exp)
      exp.shift # remove ":if" symbol from exp
      expand = Ruby2Ruby::ASSIGN_NODES.include? exp.first.first
      c = process exp.shift
      t = process exp.shift
      f = process exp.shift

      c = "(#{c.chomp})" if c =~ /\n/

      if t then
        # unless expand then
        #   if f then
        #     r = "#{c} ? (#{t}) : (#{f})"
        #     r = nil if r =~ /return/ # HACK - need contextual awareness or something
        #   else
        #     r = "#{t} if #{c}"
        #   end
        #   return r if r and (@indent+r).size < LINE_LENGTH and r !~ /\n/
        # end

        r = "if #{c} then\n#{indent(t)}\n"
        r << "else\n#{indent(f)}\n" if f
        r << "end"
        r
      else
        # unless expand then
        #   r = "#{f} unless #{c}"
        #   return r if (@indent+r).size < LINE_LENGTH and r !~ /\n/
        # end
        "unless #{c} then\n#{indent(f)}\nend"
      end
    end
  end
end

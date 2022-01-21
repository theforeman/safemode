module Safemode
  class << self
    def define_core_jail_classes
      core_classes.each do |klass|
        jail = define_jail_class(klass)
        jail.allow_instance_method *core_jail_methods(klass).uniq
        jail.allow_class_method *core_jail_class_methods(klass).uniq
        jail
      end
    end

    def define_jail_class(klass)
      unless klass.const_defined?("Jail")
        klass.const_set("Jail", jail = Class.new(Safemode::Jail))
      end
      klass.const_get('Jail')
    end

    def core_classes
      klasses = [ Array, Float, Hash, Range, String, Symbol, Time, NilClass, FalseClass, TrueClass ]
      klasses << Date if defined? Date
      klasses << DateTime if defined? DateTime
      if RUBY_VERSION >= '2.4.0'
        klasses << Integer
      else
        klasses << Bignum
        klasses << Fixnum
      end
      klasses
    end

    def core_jail_methods(klass)
      @@methods_whitelist.fetch(klass.name, []) + (@@default_methods & klass.instance_methods.map(&:to_s))
    end

    def core_jail_class_methods(klass)
      @@class_methods_whitelist.fetch(klass.name, []) + (@@default_class_methods & klass.methods.map(&:to_s))
    end
  end

  # these methods are allowed in all classes if they are present
  @@default_methods = %w( % & * ** + +@ - -@ / < << <= <=> ! != == === > >= >> ^ | ~
                          eql? equal? new methods is_a? kind_of? nil?
                          [] []= to_a to_jail to_s inspect to_param not freeze)

  # whitelisted methods for core classes ... kind of arbitrary selection
  @@methods_whitelist = {
    'Array'      => %w(any? assoc at blank? collect collect! compact compact!
                    concat delete delete_at delete_if each each_index empty?
                    fetch fill first flatten flatten! hash include? index
                    indexes indices inject insert join last length map map!
                    nitems pop push present? rassoc reject reject! reverse
                    reverse! reverse_each rindex select shift size slice
                    slice! sort sort! transpose to_sentence uniq uniq! unshift
                    values_at zip),

    'Bignum'     => %w(abs blank? ceil chr coerce div divmod downto floor hash
                    integer? modulo next nonzero? present? quo remainder round
                    singleton_method_added size step succ times to_f to_i
                    to_int to_s truncate upto zero?),

    'Fixnum'     => %w(abs blank? ceil chr coerce div divmod downto floor id2name
                    integer? modulo modulo next nonzero? present? quo remainder
                    round singleton_method_added size step succ times to_f to_i
                    to_int to_s to_sym truncate upto zero?),

    'Float'      => %w(abs blank? ceil coerce div divmod finite? floor hash
                    infinite? integer? modulo nan? nonzero? present? quo
                    remainder round singleton_method_added step to_f to_i
                    to_int to_s truncate zero?),

    'Hash'       => %w(any? blank? clear delete delete_if each each_key
                    each_pair each_value empty? fetch dig has_key? has_value?
                    include? index invert key? keys length member? merge merge!
                    present? rec_merge! rehash reject reject! select shift
                    size sort store update value? values values_at),

    'Integer'    => %w(abs blank? ceil chr coerce div divmod downto floor id2name
                    integer? modulo modulo next nonzero? present? quo remainder
                    round singleton_method_added size step succ times to_f to_i
                    to_int to_s to_sym truncate upto zero?),

    'Range'      => %w(any? begin blank? each end exclude_end? first hash
                    include? include_without_range? last member? present?
                    step),

    'String'     => %w(blank? capitalize capitalize! casecmp center chomp chomp!
                    chop chop! concat count crypt delete delete! downcase
                    downcase! dump each_byte each_line empty? end_with?
                    force_encoding gsub gsub! hash hex include? index insert
                    intern iseuc issjis isutf8 kconv length ljust lstrip
                    lstrip! match next next! oct present? reverse reverse!
                    rindex rjust rstrip rstrip! scan size slice slice! split
                    squeeze squeeze! start_with? strip strip! sub sub! succ
                    succ! sum swapcase swapcase! to_f to_i to_str to_sym to_xs
                    toeuc tojis tosjis toutf16 toutf8 tr tr! tr_s tr_s! upcase
                    upcase! upto),

    'Symbol'     => %w(blank? present? to_i to_int),

    'Time'       => %w(blank? _dump asctime ctime day dst? getgm getlocal
                    getutc gmt? gmt_offset gmtime gmtoff hash hour httpdate
                    isdst iso8601 localtime mday min minus_without_duration mon
                    month plus_without_duration present? rfc2822 rfc822 sec
                    strftime succ to_date to_datetime to_f to_i tv_sec tv_usec
                    usec utc utc? utc_offset wday xmlschema yday year zone
                    to_formatted_s),

    'Date'       => %w(ajd amjd asctime blank? ctime cwday cweek cwyear day
                    day_fraction default_inspect downto england gregorian
                    gregorian? hash italy jd julian julian? ld leap? mday
                    minus_without_duration mjd mon month new_start newsg next
                    ns? os? plus_without_duration present? sg start step
                    strftime succ upto wday yday year),

    'DateTime'   => %w(blank? hour min new_offset newof of offset present? sec
                    sec_fraction strftime to_datetime_default_s to_json zone),

    'NilClass'   => %w(blank? duplicable? present? to_f to_i),

    'FalseClass' => %w(blank? duplicable? present?),

    'TrueClass'  => %w(blank? duplicable? present?)
  }

  # these class methods are allowed on all classes if they are present
  @@default_class_methods = %w(name to_jail to_s)

  # whitelisted class methods for core classes
  @@class_methods_whitelist = {
    'String' => %w(new)
  }
end

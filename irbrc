#!/usr/bin/ruby

begin
  require 'irb/completion'
  require 'irb/ext/save-history'

  IRB.conf[:AUTO_INDENT]  = true
  IRB.conf[:USE_READLINE] = true
  IRB.conf[:SAVE_HISTORY] = 1000
  IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"
  IRB.conf[:PROMPT_MODE]  = :SIMPLE

  IRB.conf[:PROMPT][:CUSTOM] = {
    :PROMPT_I => "%03n>> ",
    :PROMPT_S => "%l>> ",
    :PROMPT_C => ".. ",
    :PROMPT_N => ".. ",
    :RETURN => "=> %s\n"
  }
  IRB.conf[:PROMPT_MODE] = :CUSTOM
  IRB.conf[:AUTO_INDENT] = true

  # Load rubygems and wirble
  # begin
  #   require 'rubygems'
  #   require 'wirble'
  #   Wirble.init
  #   Wirble.colorize
  # rescue LoadError
  # end

  ARGV.concat [ "--readline", "--prompt-mode", "simple" ]

  alias :q :exit

  %w[rubygems looksee/shortcuts wirble].each do |gem|
    begin
      require gem
    rescue LoadError
    end
  end

  class Object
    # list methods which aren't in superclass
    def local_methods(obj = self)
      (obj.methods - obj.class.superclass.instance_methods).sort
    end

    # print documentation
    #
    #   ri 'Array#pop'
    #   Array.ri
    #   Array.ri :pop
    #   arr.ri :pop
    def ri(method = nil)
      unless method && method =~ /^[A-Z]/ # if class isn't specified
        klass = self.kind_of?(Class) ? name : self.class.name
        method = [klass, method].compact.join('#')
      end
      system 'ri', method.to_s
    end
  end

  def copy(str)
    IO.popen('pbcopy', 'w') { |f| f << str.to_s }
  end

  def copy_history
    history = Readline::HISTORY.entries
    index = history.rindex("exit") || -1
    content = history[(index+1)..-2].join("\n")
    puts content
    copy content
  end

  def paste
    `pbpaste`
  end

  # TODO: alt: ascii_charts, daru, numo
  def print_histogram(array, interval: 10, return_tbl: false)
    # Group the numbers into ranges of [interval].. 10
    histogram = Hash.new(0)

    all_nums = array.map{|x| x.is_a?(Integer) || x.is_a?(Float) }.uniq
    if all_nums.size > 1 || all_nums.first == false
      # Group the values and count the occurrences
      histogram = array.group_by { |value| value }.transform_values(&:count)
      tbl = histogram
    else
      array.each do |number|
        range = (number / interval) * interval
        histogram[range] += 1
      end

      interval_cap = interval - 1
      keysort = histogram.keys.sort
      padmax = (keysort.last + interval_cap).to_s.size
      rangemax = keysort.map {|k| histogram[k] }.max + 1

      # Print the histogram
      tbl = histogram.keys.sort.map do |range|
        min = range.to_s.rjust(padmax,'0')
        max = (range + interval_cap).to_s.rjust(padmax,'0')
        "#{min} - #{max}: " + ("#" * histogram[range]).ljust(rangemax,' ') + "(#{histogram[range]})"
      end.join("\n")
    end
    return_tbl ? tbl : puts tbl
  end

  # Load Rails specific settings
  load File.expand_path('../.railsrc', __FILE__) if defined?(Rails)

rescue Exception => e
  puts "[!] ERROR loading ~/.irbrc: #{e.class} (#{e.message})"
end

begin
  require "pry"
  Pry.start
  exit
rescue LoadError => e
  warn "=> Unable to load pry"
end

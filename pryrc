Pry.config.editor = 'vim'
# Pry.config.prompt = proc { |obj, nest_level, pry| "[#{pry.input_array.size}] #{Time.now.to_s[0..-6]} #{Pry.config.prompt_name}(#{Pry.view_clip(obj)})#{(':'+nest_level) unless nest_level.zero?}> " }
Pry.config.theme = "xoria256"

def caller_local(caller_context)
  require 'open3'
  repo_path_rx = Regexp.new(Open3.capture2('pwd').first.strip)
  caller_context
    .zip((0..caller_context.size))            # line numbers
    .map(&:reverse).map(&:flatten)            # at the start
    .select{|l| l.last.match(repo_path_rx) }  # this repo only
    .map{|l| [l.first, l.last.split(":in")] } # split ref
    .reverse                                  # read top down
end
#alias :cc, :caller_local

def pp_serializer(ser)
  puts JSON.pretty_generate( ser.serializable_hash )
end

def arflush
  ActiveRecord::Base.connection.execute 'ROLLBACK'
end
alias :arrollback :arflush
alias :arclear :arflush

# TODO: alt: ascii_charts, daru, numo
def print_histogram(array, interval: 10, return_tbl: false)
  # Group the numbers into ranges of [interval].. 10
  histogram = Hash.new(0)

  all_nums = array.map{|x| x.is_a?(Integer) || x.is_a?(Float) }.uniq
  if all_nums.size > 1 || (all_nums.size == 1 && all_nums.first == false)
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

# heroku run 'bundle exec rails c -- --nomultiline' -a suvie-cloud

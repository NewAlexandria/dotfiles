#!/usr/bin/ruby

IGNORE_PATHS = %w{config}

def test_targets
  @test_targets ||= case ENV["DVCS"]
    when "svn"
      # get all the modified files that are part of the repo
      `svn status`.split("\n")
        .map(&:split)
        .reject{|chg| chg.first == '?' }
    else 
      `git diff --name-only develop`.split
    end
end

puts "nothing!" && exit unless test_targets

# presume we will run any specs that were changed
start_of_specs = test_targets.index{|x| x.last[0..3] == 'spec'}
test_runs      = (start_of_specs) ? test_targets.slice!(start_of_specs, test_targets.size) : []

def remove_paths
  # remove files from non-testable dirs
  ignore_paths = Regexp.new "^#{IGNORE_PATHS.join('^|')}"
  test_targets.reject! {|chg| chg.last.scan(ignore_paths).any? }
end

# rewrite paths in spec names, and
# reject any that do not exist
test_runs +=   test_targets.map    {|chg| [chg.first, chg.last.sub(/^app\//, '')] }.
                            map    {|m|    "spec/#{m.last.sub('.rb', '')}_spec.rb" }.
                            select {|spec| File.exists? spec}

puts "Running:"
test_runs.each {|f| puts f }
puts "============================\n\n"                                                                                                                                                                                                                                  
puts `spec #{test_runs.join(' ')} `

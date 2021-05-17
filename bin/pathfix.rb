#!/usr/bin/ruby

path = ENV['PATH'].split(':')

intel_brew_idx = path.index("/usr/local/bin")
arm_brew_idx   = path.index("/opt/homebrew/bin")
if (arm_brew_idx > intel_brew_idx) 
  ab = path.delete("/opt/homebrew/bin")
  path.insert(intel_brew_idx, ab) 
end
puts path.join(":")

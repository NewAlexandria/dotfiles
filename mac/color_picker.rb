#!/usr/bin/ruby

out = IO.popen [
 'osascript',
 '-e', 'tell application "iTerm.app"',
 '-e', '  activate',
 '-e',%|  set Applescript's text item delimiters to {"\n"}|,
 '-e', '  set col to (choose color) as text',
 '-e', 'end tell',
]

print ?#, *out.read.split.map { |color| '%02x' % (color.to_i / 256) }

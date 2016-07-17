#!/usr/bin/env ruby
require "open3"
require 'pry'
require 'ruby-progressbar'

bl = `brew list`.split
bdl = bl.reduce({}) do |h, pkg|
  out, err, st = Open3.capture3("brew deps #{pkg}")
  pkg = err.scan(/Error.*"([^"]*)".*/).flatten.first if out.empty?
  pkg_deps = (out.empty?) ?
    err.scan(/Error.*"([^"]*)".*/).flatten.first :
    out.split
  h.merge({pkg => pkg_deps })
end

bi = bl - bdl.values.flatten.compact.sort
File.open('apps_brew.txt', 'w') {|f| f.write bi.join("\n") }

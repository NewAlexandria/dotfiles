
files = Dir.
  children('.').
  select { |f| File.file?(f) } 

file_groups = files.sort.
  map{|f| (f.match(reg) || [])[0] }.
  reject(&:empty?).
  group_by{|ff| ff }.
  map{|g| [g[0].strip, g[1].size ] }.
  reject{|gg| gg[1] == 1 }

mkdirs = file_groups.
  map{|g| Dir.mkdir( File.join(Dir.pwd, g[0])) }


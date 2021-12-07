#!/usr/bin/ruby

if live_run = ARGV.delete('--live-run') || ARGV.delete('-l')
  puts '📓 This script will rename the file, but will not commit the change.'
  puts '👨‍💻 To commit the change, run `git commit -m "Rename file"`.'
else
  puts 'This script is not intended to be run directly. Instead, run `git re-mv`.'
  puts '📓 Handles the case where you have renamed a file without using git mv.'
  puts '👨‍💻 yes of course
  Will do a dry run.  To run live, use `--live-run` or `-l`.'
end

if ARGV.length != 4
  puts "We need exactly 4 arguments.  base, path, old-stem, new-stem"
  exit
end
base, path, old_stem, new_stem = ARGV

fpath = proc { |fname| [base,path,fname].join('/') }

gitFix = proc { |old,new|
  oldFile = fpath.call(old);
  newFile = fpath.call(new);
  gitmv = "mv #{newFile} #{oldFile}; git rename #{oldFile} #{newFile}"
}

commands = ff.map { |f|
  gitFix.call(
    fpath.call(f),
    fpath.call(f.gsub(/^#{old_stem}/, new_stem))
  )
}

if live_run
  puts commands
else
  commands.each { |cmd| system cmd }
end
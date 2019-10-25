require 'rubygems'
require 'rake'

DOTFILE_SKIPLIST = %w[
  Rakefile
  README.markdown
  mac
  bin
  home
  utils
  var
  _site
  LICENSE.md
]

desc "Install the dotfiles as symlinks in $HOME directory"
task :install => 'dotfiles:install'
task :default => 'dotfiles:install'

namespace :dotfiles do
  task :install do
    replace_all = false
    Dir['*'].each do |file|
      next if DOTFILE_SKIPLIST.include? file
    
      if File.exist?(File.join(ENV['HOME'], ".#{file}"))
        if replace_all
          replace_link_file(file)
        else
          print "Overwrite ~/.#{file}? [ynaq] "
          case $stdin.gets.chomp
          when 'a'
            replace_all = true
            replace_link_file(file)
          when 'y'
            replace_link_file(file)
          when 'q'
            exit
          else
            puts "Skipping ~/.#{file}"
          end
        end
      else
        link_file(file)
      end
    end
    print "Reload ~/.bash_profile? [yn] "
    if $stdin.gets.chomp == 'y'
      system "source ~/.bash_profile"
    end
  end
end

namespace :cli_utils do
  desc 'CLI utils that should be managed with Chef'
  task :install do
    Dir['utils/*'].each do |file|
      puts "\n Installing #{file.split('/').last}"
      system File.read(file)
    end
  end
end

namespace :mac do
  desc "Customize settings for Mac OS X"
  task :customize do
    system File.expand_path('../mac/customize.sh', __FILE__).to_s
  end

  desc "restore saved searches"
  task :saved_search_restore do
    lib_save_search_path = File.expand_path('~/Library/Saved\ Searches/')
    dotfiles_saved_search_path = File.expand_path('../mac/Saved\ Searches/')
    FileUtils.mkdir_p lib_save_search_path
    system "cp -f  #{dotfiles_saved_search_path}/* #{lib_save_search_path}"
  end

  desc "backup saved searches"
  task :saved_search_backup do
    lib_save_search_path = File.expand_path('~/Library/Saved\ Searches/')
    dotfiles_saved_search_path = File.expand_path('../mac/Saved\ Searches/')
    system "cp -f #{lib_save_search_path}/* #{dotfiles_saved_search_path}"
  end

  desc "Setup Mac OS X"
  task :setup do
    system File.expand_path('../mac/setup.sh', __FILE__).to_s
  end
end

def replace_link_file(file)
  system %Q{rm "$HOME/.#{file}"}
  link_file(file)
end

def link_file(file)
  puts "Linking ~/.#{file}"
  system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
end

require 'rubygems'
require 'rake'

DOTFILE_SKIPLIST = %w[
  Brewfile
  Rakefile
  mac
  bin
  home
  utils
  var
  _site
  README.markdown
  LICENSE.md
  CODE_OF_CONDUCT.md
  CONTRIBUTING.md
]

desc "Install the dotfiles as symlinks in $HOME directory"
task :install => 'dotfiles:install'
task :default => 'dotfiles:install'

def osname 
  system('
uname="$(uname -a)"
os=
arch=x86
case "$uname" in
  Linux\ *) os=linux ;;
  Darwin\ *) os=darwin ;;
  SunOS\ *) os=sunos ;;
esac
case "$uname" in
  *x86_64*) arch=x64 ;;
esac ')
end

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

    system %Q{ln -sf "$PWD/tool-versions" "$PWD/.tool-versions"}

    #print "Reload ~/.bash_profile? [yn] "
    #if $stdin.gets.chomp == 'y'
      #system "source ~/.bash_profile"
      system "source ~/.zshrc"
    #end

    system "git submodule init"
    system "git submodule sync"
    system "git submodule update"

    Rake::Task["mac:setup"].invoke if osname.match(/darwin/) 
    
    system "source ~/.zshrc"
    Rake::Task["utils:asdf"].invoke
  end
end

namespace :utils do
  desc 'setup asdf'
  task :asdf do
    system "bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'"
    toolset = File.readlines(File.expand_path('~/.tool-versions', __FILE__)).map(&:strip).map(&:split)
    toolset.map do |lang,_|
      system "asdf plugin-add #{lang}"
    end
    toolset.map do |lang,ver|
      puts "🧾 #{lang} #{ver} "
      system "asdf install #{lang} #{ver} "
    end
  end

  desc 'CLI utils that should be managed with Chef'
  task :install do
    Dir['utils/*'].each do |file|
      puts "\n Installing #{file.split('/').last}"
      system File.read(file)
    end
  end
end

namespace :mac do
  desc "Setup ZSH"
  task :setup_zsh do
    system File.expand_path('../mac/setup_zsh.sh', __FILE__).to_s
    system "ln -s ~/.dotfiles/zsh/themes/powerlevel10k ~/.oh-my-zsh/themes/powerlevel10k"
  end

  desc "install mac util configs"
  task :install_configs do
    system "mkdir -p ~/.config"
    system "rm -Rf ~/.config/karabiner ; ln -sf #{File.expand_path('../mac/karabiner', __FILE__).to_s} ~/.config/karabiner"
  end

  desc "Set application handlers for OSX"
  task :app_handlers do
    system "duti -s io.brackets.appshell .md all"
    system "duti -s com.microsoft.VSCode .ts all"
    system "duti -s com.microsoft.VSCode .js all"
    system "duti -s com.microsoft.VSCode .json all"
    system "duti -s com.microsoft.VSCode .xml all"
    system "duti -s com.microsoft.VSCode .html all"
    system "duti -s com.microsoft.VSCode .css all"
    system "duti -s com.microsoft.VSCode .rb all"
    system "duti -s com.microsoft.VSCode .erb all"
    system "duti -s com.microsoft.VSCode . all"
    system "duti -s com.microsoft.VSCode .css all"
  end

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
    Rake::Task["mac:install_configs"].invoke
    Rake::Task["mac:setup_zsh"].invoke
    puts "🔐  Remeber to setup GPG keys"
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

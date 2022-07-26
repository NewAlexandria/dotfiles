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

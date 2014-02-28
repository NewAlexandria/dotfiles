Pry.config.editor = 'vim'
Pry.config.prompt = Proc.new { |output, value| Time.now.to_s[0..-6] }

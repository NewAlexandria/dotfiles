def rgb(r, g, b)16+(r.to_i*36)+(g.to_i*6)+b.to_i end
def colorize(s, fg, bg = nil) "#{fg ? "\x1b[38;5;#{fg}m" : ''}#{bg ? "\x1b[48;5;#{bg}m" : ''}#{s}\x1b[0m" end
def rainbow(n)f,w,o=5.0/n,3,3; (0...n).map{|i| rgb(Math.sin(f*i+0)*o+w, Math.sin(f*i+2)*o+w, Math.sin(f*i+4)*o+w)} end
def display(board, goal=2048)
  @palette ||= rainbow(Math.log2(goal))
  puts board.map{|r| r.map{|c| colorize((c==0 ? ?. : c).to_s.center(6), @palette[Math.log2(c+1)])}.join}.join("\n\n")
end
 
def compress(board, direction)
  t=->(a){z=0;a.reduce([]){|s,e| z+=e==s[-1]? (s[-1]+=e;1): e>0? (s<<e;0): 1;s}+Array.new(z,0)} # trivial case: 1D array to the left
  case direction
  when :l; board.map{|e| t[e]} # 2D array to the left
  when :r; board.map{|e| t[e.reverse].reverse} # 2D array to the right
  when :u; board.transpose.map{|e| t[e]}.transpose # 2D array upwards
  when :d; board.transpose.map{|e| t[e.reverse].reverse}.transpose # 2D array downwards
  else board
  end
end
 
def add(board)
  free = board.each_with_index.reduce([]){|s,(e,i)| s+e.each_with_index.select{|d,j| d==0}.map{|k| [i,k[1]]}}.sample
  (puts 'Game over!'; exit) unless free
  board[free[0]][free[1]] = rand > 0.8 ? 4 : 2
  board
end
 
def won?(board, goal=2048)board.flatten.any?{|e| e==goal}end
 
def key
  state = `stty -g`.chomp
  system 'stty raw -echo'
  char = STDIN.getc
  char << STDIN.getc << STDIN.getc if char==0x1b.chr
  char[-1]
rescue; warn $!.message, $!.backtrace
ensure; system 'stty', state
end
 
# optional args are -w,-h for board size, -g for goal. defaults are 4,4,2048
args = Hash[ARGV.each_slice(2).to_a.map{|k,v| [k[1..-1].downcase.to_sym,v.to_i]}]
board = Array.new(args[:h]||4){Array.new(args[:w]||4, 0)}
STDIN.reopen('/dev/tty')
loop do
  board = add(board)
  system 'clear'
  display(board,args[:g]||2048)
  (puts 'You won!';exit) if won?(board, args[:g]||2048)
  direction = case key
              when ?D,?a,?h; :l # use either arrow keys or asdf or hjkl
              when ?B,?s,?j; :d
              when ?A,?w,?k; :u
              when ?C,?d,?l; :r
              when ?\C-c,?\C-x,?x,?q; exit
              else next
              end
  board = compress(board, direction)
end

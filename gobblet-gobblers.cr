require "./src/board"
require "./src/parse"
require "./src/search"

show_board = ARGV.delete("-b") ? true : false

if ARGV.size >= 1 && "nm".includes?(ARGV[0][0])
  GobbletGobblers.parse(ARGV, show_board: show_board)
elsif ARGV.size >= 2
  GobbletGobblers.search(ARGV[0].to_u64, ARGV[1].to_i)
else
  GobbletGobblers::Search.new.all_moves
end

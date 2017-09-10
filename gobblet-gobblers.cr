require "./src/board"
require "./src/search"

if ARGV.size >= 2
  GobbletGobblers.search(ARGV[0].to_u64, ARGV[1].to_i)
else
  GobbletGobblers::Search.new.all_moves
end

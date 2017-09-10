require "./src/board"
require "./src/search"

GobbletGobblers.search(ARGV[0].to_u64, ARGV[1].to_i)

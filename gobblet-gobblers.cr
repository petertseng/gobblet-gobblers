require "./src/board"

seen = Set(GobbletGobblers::Board).new

{
  GobbletGobblers::P1_BIG,
  GobbletGobblers::P1_MID,
  GobbletGobblers::P1_SMALL,
}.each { |piece|
  (0...GobbletGobblers::SIZE).each { |square|
    new_board = (piece << (square * GobbletGobblers::BITS_PER_SQUARE))
    next if seen.includes?(new_board)
    GobbletGobblers.print_board(new_board, GobbletGobblers::RED_GREEN)
    seen.add(new_board)
    GobbletGobblers::TRANSFORMS.each { |t|
      transformed = GobbletGobblers.transform(new_board, t)
      seen.add(transformed)
    }
    puts
  }
}

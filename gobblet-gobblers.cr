require "./src/board"

b = 129_u64
GobbletGobblers.print_board(b, GobbletGobblers::RED_GREEN)

GobbletGobblers::TRANSFORMS.each { |t|
  puts
  GobbletGobblers.print_board(GobbletGobblers.transform(b, t), GobbletGobblers::RED_GREEN)
}

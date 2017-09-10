module GobbletGobblers
  alias Board = UInt64

  # This is unlikely to change because 16 requires more rules
  # (off-board pieces are in stacks, can only capture from off-board in a 3-in-a-row)
  # but we'll keep it here anyway
  SIZE = 9
  ROWS = 3
  COLS = 3
  BITS_PER_SQUARE = 6
  P1_BIG = 1 << 0
  P2_BIG = 1 << 1
  P1_MID = 1 << 2
  P2_MID = 1 << 3
  P1_SMALL = 1 << 4
  P2_SMALL = 1 << 5
  MASK_PER_SQUARE = (1 << BITS_PER_SQUARE) - 1
  BITS_PER_ROW = BITS_PER_SQUARE * COLS
  MASK_PER_ROW = (1 << BITS_PER_ROW) - 1

  RED_GREEN = {31, 32}
  GREEN_RED = {32, 31}

  def self.print_board(board : Board, colours : Tuple(Int32, Int32) = {0, 0}) : Nil
    ROWS.times { |y|
      row_bits = (board >> (y * BITS_PER_ROW)) & MASK_PER_ROW
      square_bits = (0...COLS).map { |x| (row_bits >> (x * BITS_PER_SQUARE)) & MASK_PER_SQUARE }
      {
        {P1_BIG, P2_BIG},
        {P1_MID, P2_MID},
        {P1_SMALL, P2_SMALL},
      }.each { |p1, p2|
        puts square_bits.map { |square|
          if square & p1 != 0
            "\e[1;#{colours[0]}mX\e[0m"
          elsif square & p2 != 0
            "\e[1;#{colours[1]}mO\e[0m"
          else
            "."
          end
        }.join('|')
      }
      puts ("-" * (COLS * 2 - 1)) if y != ROWS - 1
    }
    nil
  end

  TRANSFORMS = {
    {0, 3, 6, 1, 4, 7, 2, 5, 8},
    {2, 5, 8, 1, 4, 7, 0, 3, 6},
    {8, 5, 2, 7, 4, 1, 6, 3, 0},
    {6, 3, 0, 7, 4, 1, 8, 5, 2},
    {2, 1, 0, 5, 4, 3, 8, 7, 6},
    {8, 7, 6, 5, 4, 3, 2, 1, 0},
    {6, 7, 8, 3, 4, 5, 0, 1, 2},
  }

  def self.transform(board : Board, permutation : Tuple(Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32)) : Board
    (((board >> (0 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[0] * BITS_PER_SQUARE)) |
    (((board >> (1 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[1] * BITS_PER_SQUARE)) |
    (((board >> (2 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[2] * BITS_PER_SQUARE)) |
    (((board >> (3 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[3] * BITS_PER_SQUARE)) |
    (((board >> (4 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[4] * BITS_PER_SQUARE)) |
    (((board >> (5 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[5] * BITS_PER_SQUARE)) |
    (((board >> (6 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[6] * BITS_PER_SQUARE)) |
    (((board >> (7 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[7] * BITS_PER_SQUARE)) |
    (((board >> (8 * BITS_PER_SQUARE)) & MASK_PER_SQUARE) << (permutation[8] * BITS_PER_SQUARE))
  end
end

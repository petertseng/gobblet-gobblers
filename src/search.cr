module GobbletGobblers
  def self.search
    seen = Set(Board).new

    {
      P1_BIG,
      P1_MID,
      P1_SMALL,
    }.each { |piece|
      (0...SIZE).each { |square|
        new_board = (piece << (square * BITS_PER_SQUARE))
        next if seen.includes?(new_board)

        # Extra space to align with moves (a1 - c3)
        puts " #{PIECE_NAMES[piece]} @ #{SQUARE_NAMES[square]}"

        seen.add(new_board)
        TRANSFORMS.each { |t|
          transformed = transform(new_board, t)
          seen.add(transformed)
        }
      }
    }
  end
end

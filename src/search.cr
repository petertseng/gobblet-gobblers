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

        print_board(new_board, RED_GREEN)
        seen.add(new_board)
        TRANSFORMS.each { |t|
          transformed = transform(new_board, t)
          seen.add(transformed)
        }
        puts
      }
    }
  end
end

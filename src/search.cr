module GobbletGobblers
  class Search
    @seen = Set(Board).new

    P1_SPARE_BIG = 1_u16 << 0
    P1_SPARE_MID = 1_u16 << 2
    P1_SPARE_SMALL = 1_u16 << 4
    P2_SPARE_BIG = 1_u16 << 6
    P2_SPARE_MID = 1_u16 << 8
    P2_SPARE_SMALL = 1_u16 << 10
    P1_HAS_SPARE_BIG = P1_SPARE_BIG * 3
    P1_HAS_SPARE_MID = P1_SPARE_MID * 3
    P1_HAS_SPARE_SMALL = P1_SPARE_SMALL * 3
    P2_HAS_SPARE_BIG = P2_SPARE_BIG * 3
    P2_HAS_SPARE_MID = P2_SPARE_MID * 3
    P2_HAS_SPARE_SMALL = P2_SPARE_SMALL * 3
    STARTING_SPARES = P1_SPARE_BIG * 2 + P1_SPARE_MID * 2 + P1_SPARE_SMALL * 2 + P2_SPARE_BIG * 2 + P2_SPARE_MID * 2 + P2_SPARE_SMALL * 2

    def winner(board : Board = 0_u64, player_to_move : Int32 = 1, spares : UInt16 = STARTING_SPARES)
      spares_present = [] of Tuple(UInt64, UInt16, Int32)

      case player_to_move
      when 1
        spares_present << {P1_BIG, P1_SPARE_BIG, 3} if spares & P1_HAS_SPARE_BIG != 0
        spares_present << {P1_MID, P1_SPARE_MID, 2} if spares & P1_HAS_SPARE_MID != 0
        spares_present << {P1_SMALL, P1_SPARE_SMALL, 1} if spares & P1_HAS_SPARE_SMALL != 0
      when 2
        spares_present << {P2_BIG, P2_SPARE_BIG, 3} if spares & P2_HAS_SPARE_BIG != 0
        spares_present << {P2_MID, P2_SPARE_MID, 2} if spares & P2_HAS_SPARE_MID != 0
        spares_present << {P2_SMALL, P2_SPARE_SMALL, 1} if spares & P2_HAS_SPARE_SMALL != 0
      else
        raise "Unknown player #{player_to_move}"
      end

      opponent = 3 - player_to_move
      heights = (0..SIZE).map { |n| GobbletGobblers.height(board, n) }

      spares_present.each { |(piece, spare, height)|
        (0...SIZE).each { |square|
          next if heights[square] >= height

          new_board = board | (piece << (square * BITS_PER_SQUARE))
          next if @seen.includes?(new_board)

          winners = GobbletGobblers.winners(new_board)
          # My opponent won on this move, don't bother making it
          next if winners[opponent - 1]

          return player_to_move if winners[player_to_move - 1]

          @seen.add(new_board)
          TRANSFORMS.each { |t|
            transformed = GobbletGobblers.transform(new_board, t)
            @seen.add(transformed)
          }

          result = winner(new_board, opponent, spares - spare)
          return player_to_move if result == player_to_move
        }
      }

      # I did not win, so my opponent does.
      opponent
    end
  end

  def self.search
    puts Search.new.winner
  end
end

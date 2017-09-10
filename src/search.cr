module GobbletGobblers
  class Search
    alias Player = Int32
    alias Spare = UInt16
    alias Spares = UInt16

    alias Result = Tuple(Player, Int32, Piece, Square?, Square)

    @cache = Hash(Board, Result?).new

    DEBUG = false

    P1_SPARE_BIG       = 1_u16 << 0
    P1_SPARE_MID       = 1_u16 << 2
    P1_SPARE_SMALL     = 1_u16 << 4
    P2_SPARE_BIG       = 1_u16 << 6
    P2_SPARE_MID       = 1_u16 << 8
    P2_SPARE_SMALL     = 1_u16 << 10
    P1_HAS_SPARE_BIG   = P1_SPARE_BIG * 3
    P1_HAS_SPARE_MID   = P1_SPARE_MID * 3
    P1_HAS_SPARE_SMALL = P1_SPARE_SMALL * 3
    P2_HAS_SPARE_BIG   = P2_SPARE_BIG * 3
    P2_HAS_SPARE_MID   = P2_SPARE_MID * 3
    P2_HAS_SPARE_SMALL = P2_SPARE_SMALL * 3
    STARTING_SPARES    = P1_SPARE_BIG * 2 + P1_SPARE_MID * 2 + P1_SPARE_SMALL * 2 + P2_SPARE_BIG * 2 + P2_SPARE_MID * 2 + P2_SPARE_SMALL * 2

    def winner(board : Board = 0_u64, player_to_move : Player = 1, spares : Spares = STARTING_SPARES)
      to_move_marker = player_to_move << BITS_PER_BOARD
      if (cached = @cache[board | to_move_marker]?)
        return cached
      end

      GobbletGobblers.print_board(board) if DEBUG

      spares_present = [] of Tuple(Piece, Spare, Height)

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

      candidates = [] of Tuple(Board, Spares, Piece, Square?, Square)

      # First, check for wins in one move.

      spares_present.each { |(piece, spare, height)|
        (0...SIZE).each { |square|
          next if heights[square] >= height

          new_board = board | (piece << (square * BITS_PER_SQUARE))

          winners = GobbletGobblers.winners(new_board)
          raise "Opponent already won, should be impossible?" if winners[opponent - 1]

          if winners[player_to_move - 1]
            result = {player_to_move, 1, piece, nil, square}
            cache(board, to_move_marker, result)
            return result
          end

          candidates << {new_board, spares - spare, piece, nil, square}
        }
      }

      (0...SIZE).each { |from_square|
        next unless GobbletGobblers.owner(board, from_square) == player_to_move
        from_height = heights[from_square]
        case {player_to_move, from_height}
        when {1, 3}; piece = P1_BIG
        when {1, 2}; piece = P1_MID
        when {1, 1}; piece = P1_SMALL
        when {2, 3}; piece = P2_BIG
        when {2, 2}; piece = P2_MID
        when {2, 1}; piece = P2_SMALL
        else         raise "Invalid piece #{player_to_move} #{from_height}"
        end
        board_without = board & ~(piece << (from_square * BITS_PER_SQUARE))

        (0...SIZE).each { |to_square|
          next if from_square == to_square
          next if heights[to_square] >= from_height

          new_board = board_without | (piece << (to_square * BITS_PER_SQUARE))

          winners = GobbletGobblers.winners(new_board)

          # My opponent won on this move, don't bother making it
          next if winners[opponent - 1]

          if winners[player_to_move - 1]
            result = {player_to_move, 1, piece, from_square, to_square}
            cache(board, to_move_marker, result)
            return result
          end

          candidates << {new_board, spares, piece, from_square, to_square}
        }
      }

      has_won = false
      fastest_win = Int32::MAX
      best_opponent_delay = 0
      best_piece = 0_u64
      best_from_square = 0
      best_to_square = 0
      opponent_to_move_marker = opponent << BITS_PER_BOARD

      candidates.each { |new_board, spares, piece, from_square, to_square|
        # Move is pending, so don't try it.
        next if @cache.has_key?(new_board | opponent_to_move_marker) && @cache[new_board | opponent_to_move_marker].nil?
        cache(new_board, opponent_to_move_marker, nil) unless @cache.has_key?(new_board | opponent_to_move_marker)

        if DEBUG
          if from_square
            puts "Move: #{PIECE_NAMES[piece]} #{SQUARE_NAMES[from_square]} - #{SQUARE_NAMES[to_square]}"
          else
            puts "Move: #{PIECE_NAMES[piece]}    @ #{SQUARE_NAMES[to_square]}"
          end
        end

        sub_winner, sub_turns, _, _, _ = winner(new_board, opponent, spares)

        if sub_winner == player_to_move
          has_won = true
          if sub_turns + 1 < fastest_win
            fastest_win = sub_turns + 1
            best_piece = piece
            best_from_square = from_square
            best_to_square = to_square
          end
        elsif !has_won && sub_turns + 1 > best_opponent_delay
          best_opponent_delay = sub_turns + 1
          best_piece = piece
          best_from_square = from_square
          best_to_square = to_square
        end
      }

      if has_won
        result = {player_to_move, fastest_win, best_piece, best_from_square, best_to_square}
      else
        # I did not win, so my opponent does.
        result = {opponent, best_opponent_delay, best_piece, best_from_square, best_to_square}
      end
      cache(board, to_move_marker, result)
      result
    end

    private def cache(board, to_move_marker, result)
      @cache[board | to_move_marker] = result
      TRANSFORMS.each { |t|
        transformed = GobbletGobblers.transform(board, t)
        @cache[transformed | to_move_marker] = result
      }
    end
  end

  def self.search
    puts Search.new.winner
  end
end

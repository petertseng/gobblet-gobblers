module GobbletGobblers
  class Search
    alias Player = Int8
    alias Spare = UInt16
    alias Spares = UInt16

    alias Move = Tuple(Piece, Square?, Square)
    alias Result = Player

    @cache = Hash(Board, Result?).new

    DEBUG = false
    SANITY = false

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

    # This might be faster than doing it in 0..8 order.
    TARGET_SQUARES = {4, 0, 2, 6, 8, 1, 3, 5, 7}

    def self.canonical(board : Board)
      c = board
      TRANSFORMS.each { |t|
        transformed = GobbletGobblers.transform(board, t)
        c = {c, transformed}.min
      }
      c
    end

    def self.legal_moves(board : Board, player_to_move : Player, spares : Spares)
      heights = (0..SIZE).map { |n| GobbletGobblers.height(board, n) }

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

      candidates = [] of Tuple(Board, Spares, Move)

      spares_present.each { |(piece, spare, height)|
        TARGET_SQUARES.each { |square|
          next if heights[square] >= height

          new_board = board | (piece << (square * BITS_PER_SQUARE))

          candidates << {new_board, spares - spare, {piece, nil, square}}
        }
      }

      opponent = 3_i8 - player_to_move

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

        TARGET_SQUARES.each { |to_square|
          next if from_square == to_square
          next if heights[to_square] >= from_height

          new_board = board_without | (piece << (to_square * BITS_PER_SQUARE))

          winners = GobbletGobblers.winners(new_board)

          # My opponent won on this move, don't bother making it
          next if winners[opponent - 1]

          candidates << {new_board, spares, {piece, from_square, to_square}}
        }
      }

      candidates
    end

    def self.move_to_s(move : Move)
      piece, from_square, to_square = move
      if from_square
        "#{PIECE_NAMES[piece]} #{SQUARE_NAMES[from_square]} - #{SQUARE_NAMES[to_square]}"
      else
        "#{PIECE_NAMES[piece]}    @ #{SQUARE_NAMES[to_square]}"
      end
    end

    def all_moves(board : Board = 0_u64, player_to_move : Player = 1_i8, spares : Spares = STARTING_SPARES)
      candidates = self.class.legal_moves(board, player_to_move, spares)
      opponent = 3_i8 - player_to_move

      candidates.each { |new_board, new_spares, move|
        winners = GobbletGobblers.winners(new_board)

        if winners[player_to_move - 1]
          puts "#{self.class.move_to_s(move)}: Win (immediate)."
          next
        end

        winner, winning_move = winner(new_board, opponent, new_spares)
        if winner == player_to_move
          puts "#{self.class.move_to_s(move)}: Win"
        else
          puts "#{self.class.move_to_s(move)}: Lose; opponent plays #{winning_move ? self.class.move_to_s(winning_move) : "unknown!"}"
        end
      }
    end

    def winner(board : Board = 0_u64, player_to_move : Player = 1_i8, spares : Spares = STARTING_SPARES)
      to_move_marker = player_to_move << BITS_PER_BOARD
      if (cached = @cache[self.class.canonical(board) | to_move_marker]?)
        return {cached, nil}
      end

      GobbletGobblers.print_board(board) if DEBUG

      opponent = 3_i8 - player_to_move

      candidates = self.class.legal_moves(board, player_to_move, spares)

      # First, check for wins in one move.
      candidates.each { |new_board, spares, move|
        winners = GobbletGobblers.winners(new_board)

        if winners[player_to_move - 1]
          cache(board, to_move_marker, player_to_move)
          return {player_to_move, move}
        end
      }

      opponent_to_move_marker = opponent << BITS_PER_BOARD

      have_tie = false

      candidates.each { |new_board, spares, move|
        # Move is pending, so don't try it.
        new_board_key = self.class.canonical(new_board) | opponent_to_move_marker
        if @cache.has_key?(new_board_key) && @cache[new_board_key].nil?
          have_tie = true
          next
        end
        cache(new_board, opponent_to_move_marker, nil) unless @cache.has_key?(new_board_key)

        puts self.class.move_to_s(move) if DEBUG

        sub_winner, _ = winner(new_board, opponent, spares)

        if sub_winner == player_to_move
          cache(board, to_move_marker, player_to_move)
          return {player_to_move, move}
        end
      }

      # I did not win, so I can tie if possible, or else lose
      winner = have_tie ? nil : opponent
      if SANITY && (cached = @cache[self.class.canonical(board) | to_move_marker]?)
        raise "Have tie but cache says it's #{cached}" if have_tie && !cached.nil?
      end
      cache(board, to_move_marker, winner)
      {winner, nil}
    end

    private def cache(board, to_move_marker, result)
      @cache[self.class.canonical(board) | to_move_marker] = result
    end
  end

  def self.search(piece, square)
    case piece
    when P1_SMALL
      spare = Search::P1_SPARE_SMALL
    when P1_MID
      spare = Search::P1_SPARE_MID
    when P1_BIG
      spare = Search::P1_SPARE_BIG
    else
      raise "Invalid piece #{piece}"
    end

    board = piece << (square * BITS_PER_SQUARE)

    print_board(board, RED_GREEN)
    winner, winning_move = Search.new.winner(board: board, player_to_move: 2_i8, spares: Search::STARTING_SPARES - spare)
    puts winner
    puts Search.move_to_s(winning_move) if winning_move
  end
end

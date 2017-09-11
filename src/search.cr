module GobbletGobblers
  class Search
    alias Player = Int8
    alias Spare = UInt16
    alias Spares = UInt16

    alias Move = Tuple(Piece, Square?, Square)
    alias Result = Tuple(Player, Move?)

    @cache = Hash(Board, Result?).new

    DEBUG  = false
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
      best = {0, 1, 2, 3, 4, 5, 6, 7, 8}

      TRANSFORMS.each { |t|
        transformed = GobbletGobblers.transform(board, t)
        if transformed < c
          c = transformed
          best = t
        end
      }

      {c, best}
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
        piece = GobbletGobblers.piece_for_height(player_to_move, from_height)
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
        elsif winner.nil?
          puts "#{self.class.move_to_s(move)}: Draw"
        else
          puts "#{self.class.move_to_s(move)}: Lose; opponent plays #{winning_move ? self.class.move_to_s(winning_move) : "unknown!"}"
        end
      }
    end

    def winner(board : Board = 0_u64, player_to_move : Player = 1_i8, spares : Spares = STARTING_SPARES)
      to_move_marker = player_to_move.to_u64 << BITS_PER_BOARD
      canonical, t = self.class.canonical(board)
      if (cached = @cache[canonical | to_move_marker]?)
        return transform_result(cached, invert(t)).not_nil!
      end

      GobbletGobblers.print_board(board) if DEBUG

      opponent = 3_i8 - player_to_move

      candidates = self.class.legal_moves(board, player_to_move, spares)

      # First, check for wins in one move.
      candidates.each { |new_board, spares, move|
        winners = GobbletGobblers.winners(new_board)

        if winners[player_to_move - 1]
          cache(board, to_move_marker, {player_to_move, move})
          return {player_to_move, move}
        end
      }

      opponent_to_move_marker = opponent.to_u64 << BITS_PER_BOARD

      have_tie = false

      candidates.each { |new_board, spares, move|
        # Move is pending, so don't try it.
        new_board_key = self.class.canonical(new_board)[0] | opponent_to_move_marker
        if @cache.has_key?(new_board_key) && @cache[new_board_key].nil?
          have_tie = true
          next
        end
        cache(new_board, opponent_to_move_marker, nil) unless @cache.has_key?(new_board_key)

        puts self.class.move_to_s(move) if DEBUG

        sub_winner, _ = winner(new_board, opponent, spares)

        if sub_winner == player_to_move
          cache(board, to_move_marker, {player_to_move, move})
          return {player_to_move, move}
        elsif sub_winner.nil?
          have_tie = true
        end
      }

      # I did not win, so I can tie if possible, or else lose
      winner = have_tie ? nil : opponent
      if SANITY && (cached = @cache[canonical | to_move_marker]?)
        raise "Have tie but cache says it's #{cached}" if have_tie && !cached[0].nil?
      end
      cache(board, to_move_marker, winner ? {winner, nil} : nil)
      {winner, nil}
    end

    private def transform_result(result : Result?, transform : Transform) : Result?
      result ? {result[0], transform_move(result[1], transform)} : nil
    end

    private def transform_move(move : Move?, transform : Transform) : Move?
      move ? {move[0], move[1] ? transform[move[1].not_nil!] : nil, transform[move[2]]} : nil
    end

    private def invert(transform : Transform) : Transform
      a = transform.to_a.map_with_index { |i, n| {i, n} }.sort
      {
        a[0][1],
        a[1][1],
        a[2][1],
        a[3][1],
        a[4][1],
        a[5][1],
        a[6][1],
        a[7][1],
        a[8][1],
      }
    end

    private def cache(board : Board, to_move_marker : UInt64, result : Result?)
      canonical, t = self.class.canonical(board)
      @cache[canonical | to_move_marker] = transform_result(result, t)
    end
  end

  def self.print_spares(spare : Search::Spares)
    {
      {"P1 Big", Search::P1_SPARE_BIG, Search::P1_HAS_SPARE_BIG},
      {"P1 Mid", Search::P1_SPARE_MID, Search::P1_HAS_SPARE_MID},
      {"P1 Small", Search::P1_SPARE_SMALL, Search::P1_HAS_SPARE_SMALL},
      {"P2 Big", Search::P2_SPARE_BIG, Search::P2_HAS_SPARE_BIG},
      {"P2 Mid", Search::P2_SPARE_MID, Search::P2_HAS_SPARE_MID},
      {"P2 Small", Search::P2_SPARE_SMALL, Search::P2_HAS_SPARE_SMALL},
    }.each { |name, one, has|
      n = (spare & has) / one
      puts "#{name}: #{n}"
    }
  end

  def self.piece_for_height(player : Search::Player, height : Int32)
    case {player, height}
    when {1, 3}; P1_BIG
    when {1, 2}; P1_MID
    when {1, 1}; P1_SMALL
    when {2, 3}; P2_BIG
    when {2, 2}; P2_MID
    when {2, 1}; P2_SMALL
    else         raise "Invalid piece #{player} #{height}"
    end
  end

  def self.spare_for(piece : Piece)
    case piece
    when P1_SMALL; {Search::P1_SPARE_SMALL, Search::P1_HAS_SPARE_SMALL}
    when P1_MID  ; {Search::P1_SPARE_MID, Search::P1_HAS_SPARE_MID}
    when P1_BIG  ; {Search::P1_SPARE_BIG, Search::P1_HAS_SPARE_BIG}
    when P2_SMALL; {Search::P2_SPARE_SMALL, Search::P2_HAS_SPARE_SMALL}
    when P2_MID  ; {Search::P2_SPARE_MID, Search::P2_HAS_SPARE_MID}
    when P2_BIG  ; {Search::P2_SPARE_BIG, Search::P2_HAS_SPARE_BIG}
    else           raise "Invalid piece #{piece}"
    end
  end

  def self.search(piece : Piece, square : Square)
    spare, _ = spare_for(piece)

    board = piece << (square * BITS_PER_SQUARE)
    spares = Search::STARTING_SPARES - spare

    print_board(board, RED_GREEN)
    print_spares(spares)
    winner, winning_move = Search.new.winner(board: board, player_to_move: 2_i8, spares: spares)
    puts winner
    puts Search.move_to_s(winning_move) if winning_move
  end
end

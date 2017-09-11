require "./search" # spare_for

module GobbletGobblers
  def self.parse(args, show_board : Bool = false)
    case args[0][0]
    when 'n'
      colours = GREEN_RED
      names = {"Nopdong", "Madong"}
    when 'm'
      colours = RED_GREEN
      names = {"Madong", "Nopdong"}
    else      raise "Unknown colour #{args[0]}"
    end

    board = 0_u64
    spares = Search::STARTING_SPARES
    player_to_move = 1_i8
    turn = 1
    search = Search.new
    have_winner = false

    args[1..-1].each { |arg|
      raise "#{arg}: Already have winner" if have_winner

      if "LlMmSs".includes?(arg[0])
        piece_to_place = PIECE_IDS[arg[0].upcase][player_to_move - 1]
        spare, has = spare_for(piece_to_place)
        square = SQUARE_IDS[arg[1..2]]

        raise "#{arg}: No more of that piece to place" if spares & has == 0

        board |= piece_to_place << (square * BITS_PER_SQUARE)
        spares -= spare
        move = {piece_to_place, nil, square}
      else
        from_square = SQUARE_IDS[arg[0..1]]
        to_square = SQUARE_IDS[arg[2..3]]
        owner = owner(board, from_square)
        raise "#{arg}: Don't own that piece" if owner != player_to_move

        height = height(board, from_square)
        piece = piece_for_height(player_to_move, height)

        board_without = board & ~(piece << (from_square * BITS_PER_SQUARE))
        board = board_without | (piece << (to_square * BITS_PER_SQUARE))

        move = {piece, from_square, to_square}
      end

      if player_to_move == 1
        print "%2d. " % turn + Search.move_to_s(move) + "           "
      else
        print "%2d.       ... " % turn + Search.move_to_s(move) + " "
        turn += 1
      end

      opponent = 3_i8 - player_to_move

      winners = winners(board)
      if winners[opponent - 1]
        puts "#{names[opponent - 1]} (Player #{opponent}) has won"
        have_winner = true
      elsif winners[player_to_move - 1]
        puts "#{names[player_to_move - 1]} (Player #{player_to_move}) has won"
        have_winner = true
      else
        player_to_move = opponent
        winner, winning_move = search.winner(board, player_to_move, spares)
        if !winner
          puts "Winner if perfect: Draw"
        elsif winning_move
          puts "Winner if perfect: #{names[winner - 1]} (Player #{winner}) - possible winning move: #{Search.move_to_s(winning_move)}"
        else
          puts "Winner if perfect: #{names[winner - 1]} (Player #{winner})"
        end
      end

      print_board(board, colours) if show_board
    }
  end
end

require 'yaml'

class SavedObjects
  attr_reader :board, :turn

  def initialize(turn:, board:)
    @turn = turn
    @board = board
  end
end

class Color
  BLACK = 0
  WHITE = 1

  def self.color_black
    return BLACK
  end

  def self.color_white
    return WHITE
  end
end

class Game
  STATES = {title_screen: 1, displaying_winner: 2, turn: 3, promoting: 4, 
    play_again: 5, exit: 6, load_game: 7, new_game: 8, help: 9}

  def initialize()
    @current_state = STATES[:title_screen]
    play
  end

  def title
    "   ..######..##.....##.########..######...######.\n   .##....##.##.....##.##.......##....##.##....##\n   .##.......##.....##.##.......##.......##......\n   .##.......#########.######....######...######.\n   .##.......##.....##.##.............##.......##\n   .##....##.##.....##.##.......##....##.##....##\n   ..######..##.....##.########..######...######.\n"
  end

  def play
    while(true)
      case @current_state

      when STATES[:title_screen]
        title_screen

      when STATES[:exit]
        system("clear") | system("cls")
        break

      when STATES[:new_game]
        new_game

      when STATES[:load_game]
        load_game

      when STATES[:turn]
        player_turn

      when STATES[:help]
        help

      else
  
      end

    end
  end

  def load_game
    savedgame = YAML.load(File.read("savegame.yml"))
    @board = savedgame.board
    @turn = savedgame.turn
    @current_state = STATES[:turn]
  end

  def title_screen
    valid_selection = false
    until valid_selection
      system("clear") | system("cls")
      puts title
      puts "\n\n"
      puts "1: New Game  2: Load Game  3: Exit".center(50)
      puts "\n\n"
      print "#{" "*13}Enter a Selection: "
      input = gets.chomp
      if input.length == 1 && "123".include?(input)
        valid_selection = true
        @current_state = STATES[:new_game] if input == "1"
        @current_state = STATES[:load_game] if input == "2"
        @current_state = STATES[:exit] if input == "3"
      else
        puts "invalid selection, press enter to continue...".center(50)
        gets
      end
    end
  end

  def player_turn
    system("clear") | system("cls")
    valid_selection = false
    until valid_selection
      player_text = @turn == Color.color_white ? "Player White" : "Player Black"
      system("clear") | system("cls")
      puts title + "\n"
      puts "Type \'help\' to see commands".center(52)
      puts "\n\n" + @board.to_text
      puts "\n\n"
      print "        #{player_text}, make your move: "
      input = gets.chomp
      
      if input == "help"
        @current_state = STATES[:help]
        valid_selection = true
      elsif input == "exit"
        @current_state = STATES[:exit]
        valid_selection = true

      elsif input == "save"
        save_game

      elsif (move = is_entered_move?(input))
        result = @board.try_move({player_color: @turn, before: move[0], after: move[1]})
        print result
        print ". press any key to continue..."
        gets
        if(result.include?("successfully moved"))
          @turn = @turn == Color.color_black ? Color.color_white : Color.color_black
        end
      else
        puts "invalid selection, press enter to continue...".center(50)
        gets
      end
    end
  end

  def save_game
    save = SavedObjects.new({board:@board, turn: @turn})
    File.open("savegame.yml", "w") {|file| file.write(save.to_yaml)}
    puts "Game saved successfully. Press any key to continue..."
    gets
    @current_state = STATES[:player_turn]
  end

  def new_game
    @board = Board.new
    @turn = Color.color_white
    @current_state = STATES[:turn]
  end

  def help
    system("clear") | system("cls")
    puts title + "\n\n"
    puts "Enter your moves in the form of PIECE DESTINATION".center(56)
    puts "eg, E2 D1 would move the piece located at E2 to D1".center (56)
    puts "\n"
    puts "Type save anytime to save the current game and exit to close ".center(60)
    puts "\n\n"
    puts "Press any key to continue...".center(50)
    gets
    @current_state = STATES[:turn]
  end

  def is_entered_move?(input)
    input = input.downcase
    split = input.split(" ")
    return false if split.length != 2
    return false if (split[0].length != 2 || split[1].length != 2)
    possible_ranges = []
    ('a'..'h').each do |n|
      ('1'..'8').each do |m|
        value1 = n.to_s + m.to_s
        value2 = m.to_s + n.to_s
        possible_ranges.push(value1)
        possible_ranges.push(value2)
      end
    end
    return false if (!possible_ranges.include?(split[0]) || !possible_ranges.include?(split[1]))

    split.map! do |o|
      o = possible_ranges.find_index(o).odd? ? possible_ranges[possible_ranges.find_index(o)-1] : o
      o = [('a'..'h').to_a.find_index(o[0]),o[1].to_i-1]
    end

    return split
  end
end


class Board
  attr_reader :board

  def initialize(board: default_board, history: default_history)
    @board = board
    @history = history
  end

  def default_board
    board = Array.new(8) {Array.new(8, nil)}
    
    #setup pawns
    (0..7).each do |num|
      board[1][num] = Pawn.new({board: self, color: Color.color_white})
      board[6][num] = Pawn.new({board: self, color: Color.color_black})
    end

    #setup others
    rows = [0,7]
    rook_col = [0,7]
    knight_col = [1,6]
    bishop_col = [2,5]

    rows.each do |row|

      color = row==0 ? Color.color_white : Color.color_black
      rook_col.each {|col| board[row][col] = Rook.new({board: self, color: color})}
      knight_col.each{|col| board[row][col] = Knight.new({board: self, color: color})}
      bishop_col.each {|col| board[row][col] = Bishop.new({board: self, color: color})}
      board[row][3] = Queen.new({board: self, color: color})
      board[row][4] = King.new({board: self, color: color})
    end
    return board
  end

  def default_history
    return {move: {}, kill: {}}
  end

  def log_move(id:, before:, after:)
    @history[:move][id.to_s] = [] if(!@history[:move].has_key?(id.to_s))
    @history[:move][id.to_s].push("#{id} moved from #{before} to #{after}")
  end

  def log_kill(id:, killed_id:)
    @history[:kill][id.to_s] = [] if(!@history[:kill].has_key?(id.to_s))
    @history[:kill][id.to_s].push(" #{id} killed #{killed_id}")

  end

  public
  def get_move_history(id:)
    move_history =  @history[:move].has_key?(id.to_s) ? @history[:move][id.to_s] : nil
    return move_history
  end

  public
  def get_location(id:)
    @board.each_with_index do |row_val, row_index|
      row_val.each_with_index do |col_val, col_index|
        return [row_index, col_index] if (col_val != nil && col_val.id == id)
      end
    end

    return nil
  end

  public
  def get_items(name:,color:)
    full_list = board.flatten.select {|n| n!=nil}
    full_list.select! {|n| n.name == name && n.color == color}
    return full_list
  end

  public
  def get_items_of_color(color:)
    full_list = board.flatten.select {|n| (n!=nil && n.color == color)}
  end

  public
  def is_in_check?(color:)
    king_loc = get_items({color: color, name: King.name})[0].location
    
    check_color = color == Color.color_black ? Color.color_white : Color.color_black
    opposing_colors = get_items_of_color({color:check_color})
    all_available_moves = []
    opposing_colors.each {|n| all_available_moves.push(n.available_moves)}
    all_available_moves.flatten!(1)
    return true if(all_available_moves.include?(king_loc))
    return false
  end

  public
  def to_text
    r_string = []
    board.each_with_index do |n, i1|
      odd_line = i1.odd?
      line1,line2,line3 = "     ","  #{('A'..'H').to_a[i1]}  ","     "
      n.each_with_index do |m, i2|
        odd_el = i2.odd?
        back_char = odd_line^odd_el ? "#" : " "

        character =  m != nil ?  m.char + " " : back_char*2
        line1 += "#{back_char*6}"
        line2 += "#{back_char*2}#{character}#{back_char*2}"
        line3 += "#{back_char*6}"
      end
      r_string.unshift(line1+"\n"+line2+"\n"+line3+"\n")
    end
    draw_board = r_string.join("")
    draw_board += "\n       1     2     3     4     5     6     7     8\n"
    return draw_board
  end


  public 
  def try_move(player_color:, before:, after:)
    while(true)


      #return message
      message = ""
      #undo stack
      undo = []
      #moving piece
      moving_piece = ""

      #check if before is on grid
      if(before[0] < 0 || before[0] > 7 || before[1] < 0 || before[1] > 7)
        message = "failed -- the coordinates you selected are off the board" 
        break
      end
    
      #check if after is on grid
      if(after[0] < 0 || after[0] > 7 || after[1] < 0 || after[1] > 7)
        message = "failed -- you're trying to move a piece off the board" 
        break
      end
      
      #check if there is a piece where you selected
      moving_piece = board[before[0]][before[1]]
      if(moving_piece == nil)
        message = "failed -- the coordinate you selected is not occupied by a piece"
        break
      end

      #check if player is allowed to move this color
      if(player_color != moving_piece.color)
        message = "failed -- the piece you are trying to move is not your color"
        break
      end

      
      #check if move is in players available moves
      if(!moving_piece.available_moves.include?(after))
        message = "failed -- that piece cannot move to that space"
        puts after.to_s
        break
      end

      #move item
      undo.push(move({before: before, after: after}))

      #check for check on self
      if(is_in_check?({color:player_color}))
        message = "failed -- you would be in check after this move"
        break
      end

      ##success##
      opponent_color = player_color == Color.color_black ? Color.color_white : Color.color_black

      #check on check for opponent
      if(is_in_check?({color:opponent_color}))
        message = "successfully moved - your opponent is now in check"
        #check for checkmate
          is_in_checkmate = true
          temp_move = []
          #get all players on opponents team
          opponent_pieces = get_items_of_color({color: opponent_color})
          opponent_pieces.each do |n|
            n.available_moves.each do |m|
              temp_move = move({before:n.location, after:m})
              is_in_checkmate = false if(!is_in_check?({color:opponent_color}))
              undo_moves(temp_move)
            end
          end
          message = "succssfully moved -- and you have forced your oppont into checkmate! YOU WIN!" if(is_in_checkmate)
        break
      else
        message = "successfully moved"
        break
      end
    end

    #check if need to undo
    if(undo != [] && message.include?("failed"))
      undo_moves(undo)
    end

    if(message.include?("successfully moved"))
      log_move({id:moving_piece.id, before: before, after: after})
      opponent = opponent_color == Color.color_white ? "White" : "Black"
      undo.flatten(1).each do |n|
        message += ". #{opponent} #{n[1]} was taken" if n[0] == "kill"
      end
    end

    return message

  end

  private
  def move(before:, after:)
    move_list = []
    moving_piece = board[before[0]][before[1]]
    target = board[after[0]][after[1]]
    move_list.push(["kill", target.name, after]) if(target!=nil)
    board[after[0]][after[1]] = moving_piece
    board[before[0]][before[1]] = nil
    move_list.push(["move", before, after])
    return move_list
  end

  private
  def undo_moves(undo)
    until(undo == [])
      move = undo.pop
      if(move[0] == "move")
        move({before:move[2],after:move[1]})
      elsif(move[0] == "kill")
        revived_piece = Object::const_get(move[1]).new
        board[move[2][0]][move[2][1]] = revived_piece
      end
    end
  end

end

class GamePiece
  attr_reader :color, :id, :name

  def initialize(board:, color:, id: default_id)
    @board = board
    @color = color
    @id = id
  end

  public
  def location
    @location = @board.get_location({id: id})
  end

  def default_id
    return ((rand*10000000)*(rand*1000000)).floor
  end

  def has_moved?
    moved = false
    moved = true if @board.get_move_history({id: id}) != nil
    return moved
  end

  def game_board
    @board.board
  end
end


class Pawn < GamePiece
  def initialize(board:, color:)
    @name = "Pawn"
    super
  end

  def available_moves
    l_y,l_x = location[0], location[1]
    forward = @color==Color.color_white ? [[1,0]] : [[-1,0]]
    two_forward = @color==Color.color_white ? [2,0] : [-2,0]
    forward.push(two_forward) if(!has_moved?)
    diagonal = @color==Color.color_white ? [[1,1],[1,-1]] : [[-1,-1],[-1,1]]
    
    moves = []
    forward.each do |move|
      m_y, m_x = move[0]+l_y, move[1]+l_x
      if(game_board[m_y][m_x]==nil && m_y < 8)
        moves.push([m_y, m_x])
      else
        break
      end
    end

    diagonal.each do |move|
      m_y, m_x = move[0]+l_y, move[1]+l_x
      if(game_board[m_y][m_x] != nil && game_board[m_y][m_x].color != @color)
        moves.push([m_y, m_x])
      end
    end

    return moves
  end

  def char
    if(@color == Color.color_white)
      return "\u265F".encode('utf-8')
    else
      return "\u2659".encode('utf-8')
    end
  end

end


class Rook < GamePiece
  def initialize(board:, color:)
    @name = "Rook"
    super
  end

  def available_moves
    l_y, l_x = location[0],location[1]
    up, down, left, right = [],[],[],[]
    (l_y+1..7).to_a.each {|n| up.push([n,l_x])}
    (0..l_y-1).to_a.reverse.each {|n| down.push([n,l_x])}
    (l_x+1..7).to_a.each {|n| right.push([l_y,n])}
    (0..l_x-1).to_a.reverse.each {|n| left.push([l_y, n])}

    moves = []
    [up,down,left,right].each do |arr|
      arr.each do |element|
        e_y,e_x = element[0],element[1]
        if(game_board[e_y][e_x]==nil)
          moves.push(element)
        else
          moves.push(element) if(game_board[e_y][e_x].color != color)
          break
        end
      end
    end

    return moves
  end

  def char
    if(@color == Color.color_white)
      return "\u265C".encode('utf-8')
    else
      return "\u2656".encode('utf-8')
    end
  end

end


class Knight < GamePiece
  def initialize(board:, color:)
    @name = "Knight"
    super
  end

  def available_moves
    l_y, l_x = location[0],location[1]
    poss = [[1,2],[2,1],[-1,2],[-2,1],[-1,-2],[-2,-1],[1,-2],[2,-1]]

    moves = []

    poss.each do |element|
      cur_y = element[0] + l_y
      cur_x = element[1] + l_x
      next if(cur_y < 0 || cur_y > 7 || cur_x < 0 || cur_y > 7)
      cur_item = game_board[cur_y][cur_x]
      moves.push([cur_y, cur_x]) if(cur_item == nil || cur_item.color != color)
    end

    return moves
  end

  def char
    if(@color == Color.color_white)
      return "\u265E".encode('utf-8')
    else
      return "\u2658".encode('utf-8')
    end
  end
end


class Bishop < GamePiece
  def initialize(board:, color:)
    @name = "Bishop"
    super
  end

  def available_moves
    l_y, l_x = location[0],location[1]
    up_r = [[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7]]
    up_l = [[1,-1],[2,-2],[3,-3],[4,-4],[5,-5],[6,-6],[7,-7]]
    down_r = [[-1,1],[-2,2],[-3,3],[-4,4],[-5,5],[-6,6],[-7,7]]
    down_l = [[-1,-1],[-2,-2],[-3,-3],[-4,-4],[-5,-5],[-6,-6],[-7,-7]]

    moves = []
    [up_r,down_r,up_l,down_l].each do |arr|
      arr.each do |element|
        normalized_element = [element[0]+l_y,element[1]+l_x]
        e_y, e_x = normalized_element[0],normalized_element[1]
        break if(e_y < 0 || e_y > 7 || e_x < 0 || e_x > 7)

        if(game_board[e_y][e_x]==nil)
          moves.push(normalized_element)
        else
          moves.push(normalized_element) if(game_board[e_y][e_x].color != color)
          break
        end
      end
    end
    return moves
  end

  def char
    if(@color == Color.color_white)
      return "\u265D".encode('utf-8')
    else
      return "\u2657".encode('utf-8')
    end
  end
end


class King < GamePiece
  def initialize(board:, color:)
    @name = "King"
    super
  end

  def available_moves
    l_y, l_x = location[0],location[1]
    poss = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[-1,0],[-1,1]]

    moves = []

    poss.each do |element|
      cur_y = element[0] + l_y
      cur_x = element[1] + l_x
      next if(cur_y < 0 || cur_y > 7 || cur_x < 0 || cur_y > 7)
      cur_item = game_board[cur_y][cur_x]
      moves.push([cur_y, cur_x]) if(cur_item == nil || cur_item.color != color)
    end

    #check castling
    rooks = @board.get_items({color: color, name:Rook.name})
    rooks.select! {|n| @board.get_move_history({id:n.id})==nil}

    if(@board.get_move_history({id:id})==nil)
      rooks.each do |n|
        if(n.location[1]<location[1])
          #left castle
          [1,2,3].each do |m|
            break if @board.board[location[0]][m] != nil
            moves.push([location[0], 0]) if m==3
          end
        else
          #right castle
          [5,6].each do |m|
            break if @board.board[location[0]][m] != nil
            moves.push([location[0], 7]) if m==6
          end
        end
      end
    end
    return moves
  end

  def char
    if(@color == Color.color_white)
      return "\u265A".encode('utf-8')
    else
      return "\u2654".encode('utf-8')
    end
  end
end


class Queen < GamePiece
  def initialize(board:, color:)
    @name = "Queen"
    super
  end

  def available_moves
    l_y, l_x = location[0],location[1]
    up, down, left, right = [],[],[],[]
    (l_y+1..7).to_a.each {|n| up.push([n,l_x])}
    (0..l_y-1).to_a.reverse.each {|n| down.push([n,l_x])}
    (l_x+1..7).to_a.each {|n| right.push([l_y,n])}
    (0..l_x-1).to_a.reverse.each {|n| left.push([l_y, n])}

    moves = []
    [up,down,left,right].each do |arr|
      arr.each do |element|
        e_y,e_x = element[0],element[1]
        if(game_board[e_y][e_x]==nil)
          moves.push(element)
        else
          moves.push(element) if(game_board[e_y][e_x].color != color)
          break
        end
      end
    end

    up_r = [[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7]]
    up_l = [[1,-1],[2,-2],[3,-3],[4,-4],[5,-5],[6,-6],[7,-7]]
    down_r = [[-1,1],[-2,2],[-3,3],[-4,4],[-5,5],[-6,6],[-7,7]]
    down_l = [[-1,-1],[-2,-2],[-3,-3],[-4,-4],[-5,-5],[-6,-6],[-7,-7]]

    [up_r,down_r,up_l,down_l].each do |arr|
      arr.each do |element|
        normalized_element = [element[0]+l_y,element[1]+l_x]
        e_y, e_x = normalized_element[0],normalized_element[1]
        break if(e_y < 0 || e_y > 7 || e_x < 0 || e_x > 7)

        if(game_board[e_y][e_x]==nil)
          moves.push(normalized_element)
        else
          moves.push(normalized_element) if(game_board[e_y][e_x].color != color)
          break
        end
      end
    end
    return moves
  end

  def char
    if(@color == Color.color_white)
      return "\u265B".encode('utf-8')
    else
      return "\u2655".encode('utf-8')
    end
  end
end

game = Game.new


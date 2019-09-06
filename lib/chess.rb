module Color
  WHITE = 2
  BLACK = 3

  def color_black 
    return BLACK
  end
  
  def color_white
    return WHITE
  end
end

class Game
  def initialize
    
  end
end

class Board
  def initialize
    
  end
end

class Square

  extend Color

  def initialize
    
  end
end

class Player
  extend Color
  attr_reader :name, :color

  def initialize(args)
    @name = args[:name]
    @color = args[:color]
  end
end

class GamePiece

  extend Color

  def initialize
    
  end
end

class Pawn < GamePiece
  def initialize
    
  end
end

class Rook < GamePiece
  def initialize
    
  end
end

class Knight < GamePiece
  def initialize
    
  end
end

class Bishop < GamePiece
  def initialize
    
  end
end

class King < GamePiece
  def initialize
    
  end
end

class Queen < GamePiece
  def initialize
    
  end
end
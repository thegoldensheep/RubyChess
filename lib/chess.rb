module Colors
  BLACK = 0
  WHITE = 1

  def self.color_black
    BLACK
  end

  def self.color_white
    white
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
  def initialize
    
  end
end

class Player
  attr_reader :name, :color

  def initialize(args)
    @name = args[:name]
    @color = args[:color]
  end
end

class GamePiece
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


puts Colors.color_black
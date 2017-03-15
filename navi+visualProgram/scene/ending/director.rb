module Ending
  class Director
	def initialize
		@ending = Image.load("./ending2.png")
	end
	def play
		Window.draw(0, 0, @ending)
	end
  end
end
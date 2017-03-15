module Title
  class Director
	def initialize
		@background = Image.load("./title2.png")
	end
	def play
		Window.draw(0, 0, @background)
		if Input.key_push?(K_SPACE)

		end
	end
  end
end
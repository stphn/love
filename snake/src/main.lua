love = love

function love.load()
	gridSize = 20
	gridWidth = 30
	gridHeight = 20

	love.window.setMode(gridWidth * gridSize, gridHeight * gridSize)

	snake = {
		{ x = 15, y = 10 },
	}

	food = {
		x = 20,
		y = 10,
	}
end

function love.update(dt)
	-- movement will go here soon
end

function love.draw()
	for i, segment in ipairs(snake) do
		local pixelX, pixelY = gridToPixels(segment.x, segment.y)
		love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
	end

	love.graphics.setColor(1, 0, 0, 1)
	local foodX, foodY = gridToPixels(food.x, food.y)
	love.graphics.rectangle("fill", foodX, foodY, gridSize, gridSize)
	love.graphics.setColor(1, 1, 1, 1)
end

function gridToPixels(gridX, gridY)
	return (gridX - 1) * gridSize, (gridY - 1) * gridSize
end

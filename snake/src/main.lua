local gridSize, gridWidth, gridHeight
local snake, food

-- Helper Functions
local function gridToPixels(gridX, gridY)
	return (gridX - 1) * gridSize, (gridY - 1) * gridSize
end

local function spawnFood()
	food.x = math.random(1, gridWidth)
	food.y = math.random(1, gridHeight)
end

local function resetGame()
	snake = {
		{ x = 15, y = 10 }, -- head
		{ x = 14, y = 10 }, -- body
		{ x = 13, y = 10 }, -- tail
	}

	food = { x = 20, y = 10 }
	direction = "right"
	moveTimer = 0
	score = 0
	gameOver = false
end

-- Initialization
function love.load()
	gridSize = 20
	gridWidth = 30
	gridHeight = 20

	moveTimer = 0
	moveDelay = 0.15
	score = 0
	highscore = 0
	gameOver = false

	baseWidth = gridWidth * gridSize -- 600
	baseHeight = gridHeight * gridSize -- 400

	love.window.setMode(baseWidth, baseHeight, {
		resizable = true,
		minwidth = baseWidth,
		minheight = baseHeight,
	})

	resetGame()
end

local function handleInput(key)
	if key == "r" then
		resetGame()
		return
	end

	if key == "p" and not gameOver then
		paused = not paused
		return
	end

	if paused then
		return
	end

	if key == "right" and direction ~= "left" then
		direction = "right"
	elseif key == "left" and direction ~= "right" then
		direction = "left"
	elseif key == "down" and direction ~= "up" then
		direction = "down"
	elseif key == "up" and direction ~= "down" then
		direction = "up"
	end
end

-- Input Handling
function love.keypressed(key)
	handleInput(key)
end

local function checkCollisions(newHead)
	-- Check for wall collision
	if newHead.x < 1 or newHead.x > gridWidth or newHead.y < 1 or newHead.y > gridHeight then
		return true
	end

	-- Check for self collision
	for i, segment in ipairs(snake) do
		if newHead.x == segment.x and newHead.y == segment.y then
			return true
		end
	end

	return false
end

local function updateSnakeMovement(dt)
	moveTimer = moveTimer + dt

	if moveTimer >= moveDelay then
		moveTimer = 0

		local head = snake[1]
		local newHead = { x = head.x, y = head.y }

		-- Calculate new head position based on direction
		if direction == "right" then
			newHead.x = newHead.x + 1
		elseif direction == "left" then
			newHead.x = newHead.x - 1
		elseif direction == "down" then
			newHead.y = newHead.y + 1
		elseif direction == "up" then
			newHead.y = newHead.y - 1
		end

		-- Check for collisions
		if checkCollisions(newHead) then
			gameOver = true
			return
		end

		-- Add new head
		table.insert(snake, 1, newHead)

		-- Check if food was eaten
		if newHead.x == food.x and newHead.y == food.y then
			score = score + 1
			if score > highscore then
				highscore = score
			end
			spawnFood()
		else
			-- No food eaten, remove tail (snake doesn't grow)
			table.remove(snake)
		end
	end
end

-- Game Update
function love.update(dt)
	if gameOver or paused then
		return
	end

	updateSnakeMovement(dt)
end

-- Drawing Functions
local function drawSnake()
	for i, segment in ipairs(snake) do
		local pixelX, pixelY = gridToPixels(segment.x, segment.y)
		love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
	end
end

local function drawFood()
	love.graphics.setColor(1, 0, 0, 1)
	local foodX, foodY = gridToPixels(food.x, food.y)
	love.graphics.rectangle("fill", foodX, foodY, gridSize, gridSize)
	love.graphics.setColor(1, 1, 1, 1)
end

local function drawUI()
	love.graphics.print("score: " .. score, 10, 10)
	love.graphics.print("highscore: " .. highscore, 10, 30)
end

local function drawGameOver()
	if gameOver then
		love.graphics.setColor(1, 0, 0)
		love.graphics.print("GAME OVER! Press R to restart", 150, 200, 0, 2, 2)
		love.graphics.setColor(1, 1, 1)
	end
end

-- Rendering
function love.draw()
	-- calculate scale to fit window
	local windowWidth, windowHeight = love.graphics.getDimensions()
	local scaleX = windowWidth / baseWidth
	local scaleY = windowHeight / baseHeight
	local scale = math.min(scaleX, scaleY) -- keep aspect ratio

	-- Center the game
	local offsetX = (windowWidth - baseWidth * scale) / 2
	local offsetY = (windowHeight - baseHeight * scale) / 2

	love.graphics.push()
	love.graphics.translate(offsetX, offsetY)
	love.graphics.scale(scale, scale)

	drawSnake()
	drawFood()
	drawUI()
	drawGameOver()

	love.graphics.pop()
end

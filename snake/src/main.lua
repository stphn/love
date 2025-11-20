local gridSize, gridWidth, gridHeight
local snake, food

-- Helper Functions
local function gridToPixels(gridX, gridY)
	return (gridX - 1) * gridSize, (gridY - 1) * gridSize
end

-- LCD 7-segment patterns for digits (3x5 grid for each digit)
-- Each digit is represented as a table of {x, y} coordinates relative to digit origin
local lcdDigits = {
	[0] = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, {3,2}, -- upper sides
		{1,3}, {3,3}, -- middle sides
		{1,4}, {3,4}, -- lower sides
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	[1] = {
		{3,1}, {3,2}, {3,3}, {3,4}, {3,5}, -- right side
	},
	[2] = {
		{1,1}, {2,1}, {3,1}, -- top
		{3,2}, -- upper right
		{1,3}, {2,3}, {3,3}, -- middle
		{1,4}, -- lower left
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	[3] = {
		{1,1}, {2,1}, {3,1}, -- top
		{3,2}, -- upper right
		{1,3}, {2,3}, {3,3}, -- middle
		{3,4}, -- lower right
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	[4] = {
		{1,1}, {3,1}, -- top corners
		{1,2}, {3,2}, -- upper sides
		{1,3}, {2,3}, {3,3}, -- middle
		{3,4}, {3,5}, -- right side
	},
	[5] = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, -- upper left
		{1,3}, {2,3}, {3,3}, -- middle
		{3,4}, -- lower right
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	[6] = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, -- upper left
		{1,3}, {2,3}, {3,3}, -- middle
		{1,4}, {3,4}, -- lower sides
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	[7] = {
		{1,1}, {2,1}, {3,1}, -- top
		{3,2}, {3,3}, {3,4}, {3,5}, -- right side
	},
	[8] = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, {3,2}, -- upper sides
		{1,3}, {2,3}, {3,3}, -- middle
		{1,4}, {3,4}, -- lower sides
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	[9] = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, {3,2}, -- upper sides
		{1,3}, {2,3}, {3,3}, -- middle
		{3,4}, -- lower right
		{1,5}, {2,5}, {3,5}, -- bottom
	},
}

-- LCD letter patterns (3x5 grid for each letter)
local lcdLetters = {
	G = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, -- left side
		{1,3}, {2,3}, {3,3}, -- middle with right
		{1,4}, {3,4}, -- sides
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	A = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, {3,2}, -- upper sides
		{1,3}, {2,3}, {3,3}, -- middle
		{1,4}, {3,4}, -- lower sides
		{1,5}, {3,5}, -- bottom corners
	},
	M = {
		{1,1}, {1,2}, {1,3}, {1,4}, {1,5}, -- left side
		{2,2}, -- left peak
		{3,1}, {3,2}, {3,3}, {3,4}, {3,5}, -- right side
	},
	E = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, -- left
		{1,3}, {2,3}, {3,3}, -- middle
		{1,4}, -- left
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	O = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, {3,2}, -- upper sides
		{1,3}, {3,3}, -- middle sides
		{1,4}, {3,4}, -- lower sides
		{1,5}, {2,5}, {3,5}, -- bottom
	},
	V = {
		{1,1}, {1,2}, {1,3}, {1,4}, -- left side
		{2,5}, -- bottom center
		{3,1}, {3,2}, {3,3}, {3,4}, -- right side
	},
	R = {
		{1,1}, {2,1}, {3,1}, -- top
		{1,2}, {3,2}, -- upper sides
		{1,3}, {2,3}, {3,3}, -- middle
		{1,4}, {3,4}, -- lower sides
		{1,5}, {3,5}, -- bottom corners
	},
}

local function calculateManhattanDistance(x1, y1, x2, y2)
	return math.abs(x2 - x1) + math.abs(y2 - y1)
end

local function spawnFood()
	food.x = math.random(1, gridWidth)
	food.y = math.random(1, gridHeight)
	foodTimer = 0
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
	paused = false
	foodTimer = 0
	gameOverColorTimer = 0
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
	foodTimer = 0
	gameOverColorTimer = 0

	baseWidth = gridWidth * gridSize -- 600
	baseHeight = gridHeight * gridSize -- 400

	love.window.setMode(baseWidth, baseHeight, {
		resizable = true,
		minwidth = baseWidth,
		minheight = baseHeight,
	})

	fontSmall = love.graphics.newFont("fonts/Kenney Pixel.ttf", 14)
	fontMedium = love.graphics.newFont("fonts/Kenney Pixel.ttf", 24)
	fontLarge = love.graphics.newFont("fonts/Kenney Pixel.ttf", 48)

	sounds = {
		ambiance = love.audio.newSource("audio/ambiance.ogg", "stream"),
		eat = love.audio.newSource("audio/powerUp5.ogg", "static"),
		die = love.audio.newSource("audio/lowDown.ogg", "static"),
		ui = love.audio.newSource("audio/switch10.ogg", "static"),
	}
	sounds.ambiance:setLooping(true)
	sounds.ambiance:play()

	-- Create particle system for eating effect
	local particleImage = love.graphics.newCanvas(4, 4)
	love.graphics.setCanvas(particleImage)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", 0, 0, 4, 4)
	love.graphics.setCanvas()

	particleSystem = love.graphics.newParticleSystem(particleImage, 20)
	particleSystem:setParticleLifetime(0.3, 0.6)
	particleSystem:setEmissionRate(0)
	particleSystem:setSizeVariation(1)
	particleSystem:setLinearAcceleration(-100, -100, 100, 100)
	particleSystem:setSpeed(50, 150)
	particleSystem:setSizes(1, 0.5, 0)
	particleSystem:setSpread(math.pi * 2)

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

local function updateSpeed()
	-- Adjusted thresholds for new scoring system (up to 5 pts per apple)
	if score < 15 then
		moveDelay = 0.15
	elseif score < 30 then
		moveDelay = 0.13
	elseif score < 50 then
		moveDelay = 0.11
	elseif score < 75 then
		moveDelay = 0.09
	elseif score < 100 then
		moveDelay = 0.07
	else
		moveDelay = 0.06
	end
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
			sounds.die:play()
			return
		end

		-- Add new head
		table.insert(snake, 1, newHead)

		-- Check if food was eaten
		if newHead.x == food.x and newHead.y == food.y then
			-- Calculate score based on apple ripeness (5 decay stages)
			-- Fresh green: < 1.2 sec = 3 points (unripe, tart)
			-- Perfect red: 1.2-2.4 sec = 5 points (ripe, sweet - best!)
			-- Overripe burgundy: 2.4-3.6 sec = 2 points (getting soft)
			-- Rotten brown: 3.6-4.8 sec = 1 point (spoiled)
			-- Moldy black: > 4.8 sec = -1 point (toxic!)
			local pointsEarned = -1
			if foodTimer < 1.2 then
				pointsEarned = 3
			elseif foodTimer < 2.4 then
				pointsEarned = 5
			elseif foodTimer < 3.6 then
				pointsEarned = 2
			elseif foodTimer < 4.8 then
				pointsEarned = 1
			end

			-- Emit particles at food position with apple's color
			local foodX, foodY = gridToPixels(food.x, food.y)
			local particleX = foodX + gridSize / 2
			local particleY = foodY + gridSize / 2

			-- Set particle color based on apple state
			local r, g, b = 1, 1, 1
			if foodTimer < 1.2 then
				r, g, b = 0.4, 1, 0.2 -- Lime
			elseif foodTimer < 2.4 then
				r, g, b = 1, 0.1, 0.1 -- Red
			elseif foodTimer < 3.6 then
				r, g, b = 0.7, 0.1, 0.3 -- Burgundy
			elseif foodTimer < 4.8 then
				r, g, b = 0.6, 0.3, 0.1 -- Orange
			else
				r, g, b = 0.6, 0.2, 0.6 -- Purple
			end

			particleSystem:setColors(r, g, b, 1, r, g, b, 0)
			particleSystem:setPosition(particleX, particleY)
			particleSystem:emit(15)

			score = score + pointsEarned
			updateSpeed()
			sounds.eat:setVolume(0.2)
			sounds.eat:play()
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
	if gameOver then
		gameOverColorTimer = gameOverColorTimer + dt
		particleSystem:update(dt)
		return
	end

	if paused then
		return
	end

	foodTimer = foodTimer + dt
	particleSystem:update(dt)
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
	-- Natural apple decay colors (5 stages) - more vibrant!
	-- Fresh green: 0-1.2 sec (unripe)
	-- Perfect red: 1.2-2.4 sec (ripe, sweet)
	-- Overripe burgundy: 2.4-3.6 sec (getting soft)
	-- Rotten brown: 3.6-4.8 sec (spoiled)
	-- Moldy purple: > 4.8 sec (toxic!)
	local r, g, b = 1, 0, 0 -- default red

	if foodTimer < 1.2 then
		-- Bright lime green (fresh, unripe)
		r, g, b = 0.4, 1, 0.2
	elseif foodTimer < 2.4 then
		-- Vibrant red (perfect, ripe!)
		r, g, b = 1, 0.1, 0.1
	elseif foodTimer < 3.6 then
		-- Deep burgundy/wine (overripe)
		r, g, b = 0.7, 0.1, 0.3
	elseif foodTimer < 4.8 then
		-- Dark orange/brown (rotten)
		r, g, b = 0.6, 0.3, 0.1
	else
		-- Toxic purple/magenta (moldy - more visible!)
		r, g, b = 0.6, 0.2, 0.6
	end

	love.graphics.setColor(r, g, b, 1)
	local foodX, foodY = gridToPixels(food.x, food.y)
	love.graphics.rectangle("fill", foodX, foodY, gridSize, gridSize)
	love.graphics.setColor(1, 1, 1, 1)
end

local function drawLCDDigit(digit, startX, startY)
	local pattern = lcdDigits[digit]
	if pattern then
		for _, coord in ipairs(pattern) do
			local pixelX = startX + (coord[1] - 1) * gridSize
			local pixelY = startY + (coord[2] - 1) * gridSize
			love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
		end
	end
end

local function drawLCDLetter(letter, startX, startY)
	local pattern = lcdLetters[letter]
	if pattern then
		for _, coord in ipairs(pattern) do
			local pixelX = startX + (coord[1] - 1) * gridSize
			local pixelY = startY + (coord[2] - 1) * gridSize
			love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
		end
	end
end

local function drawLCDText(text, startX, startY)
	local currentX = startX
	for i = 1, #text do
		local char = text:sub(i, i)
		if char ~= " " then
			drawLCDLetter(char, currentX, startY)
		end
		-- Move to next character position (3 cells width + 1 cell spacing)
		currentX = currentX + 4 * gridSize
	end
end

local function drawLCDScore()
	local scoreStr = string.format("%04d", math.min(score, 9999))

	-- Determine how many digits to highlight
	local digitsToShow = math.max(1, math.floor(math.log10(math.max(score, 1))) + 1)

	-- Center position: 15 cells wide (4 digits * 4 cells each), 5 cells tall
	local startGridX = math.floor((gridWidth - 15) / 2) + 1
	local startGridY = math.floor((gridHeight - 5) / 2) + 1
	local startX, startY = gridToPixels(startGridX, startGridY)

	-- Draw background "8888"
	love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
	for i = 1, 4 do
		local digitX = gridToPixels(startGridX + (i - 1) * 4, startGridY)
		drawLCDDigit(8, digitX, startY)
	end

	-- Draw score digits in simple gray
	love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
	for i = 1, 4 do
		if i > (4 - digitsToShow) then
			local digit = tonumber(scoreStr:sub(i, i))
			local digitX = gridToPixels(startGridX + (i - 1) * 4, startGridY)
			drawLCDDigit(digit, digitX, startY)
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end

local function drawUI()
	love.graphics.setFont(fontSmall)
	love.graphics.print("highscore: " .. highscore, 10, 10)
end

local function drawDebugInfo()
	love.graphics.setFont(fontSmall)
	love.graphics.setColor(0.7, 0.7, 0.7, 1)

	local debugY = baseHeight - 60
	love.graphics.print("DEBUG INFO:", 10, debugY)
	love.graphics.print("Food Timer: " .. string.format("%.1f", foodTimer) .. "s", 10, debugY + 15)

	-- Determine color stage and points (5 stages)
	local colorStage = "Purple (Moldy!)"
	local pointsEarned = -1
	if foodTimer < 1.2 then
		colorStage = "Lime (Unripe)"
		pointsEarned = 3
	elseif foodTimer < 2.4 then
		colorStage = "Red (Perfect!)"
		pointsEarned = 5
	elseif foodTimer < 3.6 then
		colorStage = "Burgundy (Overripe)"
		pointsEarned = 2
	elseif foodTimer < 4.8 then
		colorStage = "Orange (Rotten)"
		pointsEarned = 1
	end

	love.graphics.print("Color: " .. colorStage, 10, debugY + 30)
	love.graphics.print("Next Points: " .. pointsEarned, 10, debugY + 45)

	love.graphics.setColor(1, 1, 1, 1)
end

local function drawGameOver()
	if gameOver then
		-- "GAME" = 4 characters, "OVER" = 4 characters
		-- Each character is 3 cells wide + 1 cell spacing = 4 cells per char
		-- Width: 4 * 4 = 16 cells
		local lineWidth = 4 * 4 * gridSize
		local lineHeight = 5 * gridSize
		local lineSpacing = 2 * gridSize -- 2 cells spacing between lines

		-- Center both lines
		local gameX = (baseWidth - lineWidth) / 2
		local totalHeight = 2 * lineHeight + lineSpacing
		local startY = (baseHeight - totalHeight) / 2

		-- Retro rainbow animation - cycle through colors
		-- Using HSV to RGB conversion for smooth color cycling
		local hue = (gameOverColorTimer * 0.5) % 1 -- Cycle every 2 seconds
		local r, g, b

		-- Simple HSV to RGB (S=1, V=1)
		local h = hue * 6
		local x = 1 - math.abs((h % 2) - 1)

		if h < 1 then
			r, g, b = 1, x, 0
		elseif h < 2 then
			r, g, b = x, 1, 0
		elseif h < 3 then
			r, g, b = 0, 1, x
		elseif h < 4 then
			r, g, b = 0, x, 1
		elseif h < 5 then
			r, g, b = x, 0, 1
		else
			r, g, b = 1, 0, x
		end

		-- Draw "GAME" and "OVER" with animated color
		love.graphics.setColor(r, g, b, 1)
		drawLCDText("GAME", gameX, startY)
		drawLCDText("OVER", gameX, startY + lineHeight + lineSpacing)

		love.graphics.setColor(1, 1, 1, 1)
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

	-- Draw window background (dark gray letterbox/pillarbox)
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

	love.graphics.push()
	love.graphics.translate(offsetX, offsetY)
	love.graphics.scale(scale, scale)

	-- Draw game area background (slightly lighter for contrast)
	love.graphics.setColor(0.15, 0.15, 0.15)
	love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)

	-- Draw game border
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", 0, 0, baseWidth, baseHeight)

	-- Reset color for game objects
	love.graphics.setColor(1, 1, 1)

	drawLCDScore()
	drawSnake()
	drawFood()
	love.graphics.draw(particleSystem, 0, 0)
	drawUI()
	drawDebugInfo()
	drawGameOver()

	love.graphics.pop()
end

local lcd = require("lcd")

local gridSize, gridWidth, gridHeight
local snake, food
local gameState -- "menu", "playing", "instructions", "gameover"
local selectedMenuOption
local menuOptions
local gameMode -- "classic" or "zen"

-- Helper Functions
local function gridToPixels(gridX, gridY)
	return (gridX - 1) * gridSize, (gridY - 1) * gridSize
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
	-- Set nearest neighbor filtering for crisp pixels/fonts
	love.graphics.setDefaultFilter("nearest", "nearest")

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
	gameState = "menu"
	selectedMenuOption = 1
	menuOptions = { "Classic Mode", "Zen Mode", "Instructions", "Quit" }
	gameMode = "classic"

	baseWidth = gridWidth * gridSize -- 600
	baseHeight = gridHeight * gridSize -- 400

	love.window.setMode(baseWidth, baseHeight, {
		resizable = true,
		minwidth = baseWidth,
		minheight = baseHeight,
	})

	fontSmall = love.graphics.newFont("fonts/Kenney Future.ttf", 14)
	fontMedium = love.graphics.newFont("fonts/Kenney Future.ttf", 24)
	fontLarge = love.graphics.newFont("fonts/Kenney Future.ttf", 48)
	fontTitle = love.graphics.newFont("fonts/Kenney Blocks.ttf", 64)

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

local function handleMenuInput(key)
	if key == "up" then
		selectedMenuOption = selectedMenuOption - 1
		if selectedMenuOption < 1 then
			selectedMenuOption = #menuOptions
		end
		sounds.ui:play()
	elseif key == "down" then
		selectedMenuOption = selectedMenuOption + 1
		if selectedMenuOption > #menuOptions then
			selectedMenuOption = 1
		end
		sounds.ui:play()
	elseif key == "return" or key == "space" then
		sounds.ui:play()
		if selectedMenuOption == 1 then
			-- Classic Mode
			gameMode = "classic"
			gameState = "playing"
			resetGame()
		elseif selectedMenuOption == 2 then
			-- Zen Mode
			gameMode = "zen"
			gameState = "playing"
			resetGame()
		elseif selectedMenuOption == 3 then
			-- Instructions
			gameState = "instructions"
		elseif selectedMenuOption == 4 then
			-- Quit
			love.event.quit()
		end
	end
end

local function handleInstructionsInput(key)
	if key == "escape" or key == "return" or key == "space" then
		sounds.ui:play()
		gameState = "menu"
	end
end

local function handleGameInput(key)
	if gameOver then
		if key == "r" then
			resetGame()
			return
		elseif key == "escape" or key == "return" then
			gameState = "menu"
			sounds.ui:play()
			return
		end
		return
	end

	if key == "r" then
		resetGame()
		return
	end

	if key == "escape" then
		gameState = "menu"
		sounds.ui:play()
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

local function handleInput(key)
	if gameState == "menu" then
		handleMenuInput(key)
	elseif gameState == "instructions" then
		handleInstructionsInput(key)
	elseif gameState == "playing" then
		handleGameInput(key)
	end
end

-- Input Handling
function love.keypressed(key)
	handleInput(key)
end

local function checkCollisions(newHead)
	-- Check for wall collision (only in classic mode)
	if gameMode == "classic" then
		if newHead.x < 1 or newHead.x > gridWidth or newHead.y < 1 or newHead.y > gridHeight then
			return true
		end
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

		-- Wrap around walls in zen mode
		if gameMode == "zen" then
			if newHead.x < 1 then
				newHead.x = gridWidth
			elseif newHead.x > gridWidth then
				newHead.x = 1
			end
			if newHead.y < 1 then
				newHead.y = gridHeight
			elseif newHead.y > gridHeight then
				newHead.y = 1
			end
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
			local pointsEarned
			local r, g, b

			-- In zen mode, always give 5 points and red color
			if gameMode == "zen" then
				pointsEarned = 5
				r, g, b = 1, 0.1, 0.1 -- Red
			else
				-- Classic mode: Calculate score based on apple ripeness (5 decay stages)
				-- Fresh green: < 1.2 sec = 3 points (unripe, tart)
				-- Perfect red: 1.2-2.4 sec = 5 points (ripe, sweet - best!)
				-- Overripe burgundy: 2.4-3.6 sec = 2 points (getting soft)
				-- Rotten brown: 3.6-4.8 sec = 1 point (spoiled)
				-- Moldy black: > 4.8 sec = -1 point (toxic!)
				pointsEarned = -1
				if foodTimer < 1.2 then
					pointsEarned = 3
					r, g, b = 0.4, 1, 0.2 -- Lime
				elseif foodTimer < 2.4 then
					pointsEarned = 5
					r, g, b = 1, 0.1, 0.1 -- Red
				elseif foodTimer < 3.6 then
					pointsEarned = 2
					r, g, b = 0.7, 0.1, 0.3 -- Burgundy
				elseif foodTimer < 4.8 then
					pointsEarned = 1
					r, g, b = 0.6, 0.3, 0.1 -- Orange
				else
					r, g, b = 0.6, 0.2, 0.6 -- Purple
				end
			end

			-- Emit particles at food position with apple's color
			local foodX, foodY = gridToPixels(food.x, food.y)
			local particleX = foodX + gridSize / 2
			local particleY = foodY + gridSize / 2

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
	if gameState ~= "playing" then
		return
	end

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
	love.graphics.setColor(1, 1, 1, 1)
	for i, segment in ipairs(snake) do
		local pixelX, pixelY = gridToPixels(segment.x, segment.y)
		love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
	end
end

local function drawFood()
	local r, g, b = 1, 0.1, 0.1 -- default red

	-- In zen mode, always show red apple
	if gameMode == "zen" then
		r, g, b = 1, 0.1, 0.1 -- Vibrant red
	else
		-- Classic mode: Natural apple decay colors (5 stages)
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
	end

	love.graphics.setColor(r, g, b, 1)
	local foodX, foodY = gridToPixels(food.x, food.y)
	love.graphics.rectangle("fill", foodX, foodY, gridSize, gridSize)
	love.graphics.setColor(1, 1, 1, 1)
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
		lcd.drawDigit(8, digitX, startY, gridSize)
	end

	-- Draw score digits in simple gray
	love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
	for i = 1, 4 do
		if i > (4 - digitsToShow) then
			local digit = tonumber(scoreStr:sub(i, i))
			local digitX = gridToPixels(startGridX + (i - 1) * 4, startGridY)
			lcd.drawDigit(digit, digitX, startY, gridSize)
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
		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 0, 0, baseWidth, baseHeight)

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
		lcd.drawText("GAME", gameX, startY, gridSize)
		lcd.drawText("OVER", gameX, startY + lineHeight + lineSpacing, gridSize)

		-- Draw hints below
		love.graphics.setFont(fontSmall)
		love.graphics.setColor(1, 1, 1, 1)
		local hint1 = "Press R to restart"
		local hint2 = "Press ESC or ENTER to return to menu"
		local hint1Width = fontSmall:getWidth(hint1)
		local hint2Width = fontSmall:getWidth(hint2)
		local hintY = startY + 2 * lineHeight + lineSpacing + 40
		love.graphics.print(hint1, (baseWidth - hint1Width) / 2, hintY)
		love.graphics.print(hint2, (baseWidth - hint2Width) / 2, hintY + 20)

		love.graphics.setColor(1, 1, 1, 1)
	end
end

local function drawMenu()
	love.graphics.setColor(1, 1, 1, 1)

	-- Title
	love.graphics.setFont(fontTitle)
	local title = "SNAKE"
	local titleWidth = fontTitle:getWidth(title)
	love.graphics.print(title, (baseWidth - titleWidth) / 2, 50)

	-- Menu options
	love.graphics.setFont(fontMedium)
	local startY = 200
	local spacing = 50

	for i, option in ipairs(menuOptions) do
		local optionWidth = fontMedium:getWidth(option)
		local x = (baseWidth - optionWidth) / 2
		local y = startY + (i - 1) * spacing

		if i == selectedMenuOption then
			-- Draw selection indicators on sides
			love.graphics.setColor(0.4, 1, 0.2, 1) -- Lime green
			love.graphics.print(">", x - 30, y)
			love.graphics.print("<", x + optionWidth + 20, y)
			love.graphics.print(option, x, y)
		else
			love.graphics.setColor(0.7, 0.7, 0.7, 1)
			love.graphics.print(option, x, y)
		end
	end

	-- Controls hint
	love.graphics.setFont(fontSmall)
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	local hint = "Use UP/DOWN to select, ENTER to confirm"
	local hintWidth = fontSmall:getWidth(hint)
	love.graphics.print(hint, (baseWidth - hintWidth) / 2, baseHeight - 40)

	love.graphics.setColor(1, 1, 1, 1)
end

local function drawInstructions()
	love.graphics.setColor(1, 1, 1, 1)

	-- Title
	love.graphics.setFont(fontMedium)
	local title = "HOW TO PLAY"
	love.graphics.print(title, 30, 20)

	love.graphics.setFont(fontSmall)
	local lineHeight = 18
	local sectionSpacing = 30 -- Equal spacing between sections
	local leftX = 30
	local rightX = 320
	local startY = 70
	local currentY = startY

	-- Left Column: Controls
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("CONTROLS:", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  Arrow Keys - Move", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  P - Pause", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  R - Restart", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  ESC - Menu", leftX, currentY)
	currentY = currentY + sectionSpacing

	-- Objective
	love.graphics.print("OBJECTIVE:", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  Eat apples to grow", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  and score points.", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  Don't hit walls or", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  yourself!", leftX, currentY)
	currentY = currentY + sectionSpacing

	-- Tip
	love.graphics.print("TIP:", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  The game speeds up", leftX, currentY)
	currentY = currentY + lineHeight
	love.graphics.print("  as you score more.", leftX, currentY)

	-- Right Column: Apple Ripeness System
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("APPLE RIPENESS:", rightX, startY)

	local appleData = {
		{ color = { 0.4, 1, 0.2 }, text = "3 pts (unripe)" },
		{ color = { 1, 0.1, 0.1 }, text = "5 pts (perfect!)" },
		{ color = { 0.7, 0.1, 0.3 }, text = "2 pts" },
		{ color = { 0.6, 0.3, 0.1 }, text = "1 pt" },
		{ color = { 0.6, 0.2, 0.6 }, text = "-1 pt (toxic!)" },
	}

	local appleStartY = startY + lineHeight * 2
	local squareSize = 10
	local squareX = rightX + 5

	for i, apple in ipairs(appleData) do
		local y = appleStartY + (i - 1) * lineHeight

		-- Draw colored square
		love.graphics.setColor(apple.color[1], apple.color[2], apple.color[3], 1)
		love.graphics.rectangle("fill", squareX, y + 2, squareSize, squareSize)

		-- Draw text
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(apple.text, squareX + squareSize + 8, y)
	end

	-- Additional info
	love.graphics.setColor(0.8, 0.8, 0.8, 1)
	love.graphics.print("Apples change color", rightX, appleStartY + 6 * lineHeight)
	love.graphics.print("over time!", rightX, appleStartY + 7 * lineHeight)

	-- Back hint
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	local hint = "Press ENTER or ESC to return"
	local hintWidth = fontSmall:getWidth(hint)
	love.graphics.print(hint, (baseWidth - hintWidth) / 2, baseHeight - 25)

	love.graphics.setColor(1, 1, 1, 1)
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

	if gameState == "menu" then
		drawMenu()
	elseif gameState == "instructions" then
		drawInstructions()
	elseif gameState == "playing" then
		drawLCDScore()
		drawSnake()
		drawFood()
		love.graphics.draw(particleSystem, 0, 0)
		drawUI()
		-- drawDebugInfo()
		drawGameOver()
	end

	love.graphics.pop()
end

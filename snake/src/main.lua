local lcd = require("lcd")

local gridSize, gridWidth, gridHeight
local snake, food
local gameState -- "menu", "playing", "instructions", "gameover"
local selectedMenuOption
local menuOptions
local gameMode -- "classic", "zen", or "survival"
local instructionPage -- 1 = controls/classic, 2 = zen, 3 = survival

-- Helper Functions
local function gridToPixels(gridX, gridY)
	return (gridX - 1) * gridSize, (gridY - 1) * gridSize
end

local function playSound(sound)
	if not soundsMuted then
		sound:play()
	end
end

local function spawnFood()
	food.x = math.random(1, gridWidth)
	food.y = math.random(1, gridHeight)
	foodTimer = 0
end

local function resetGame()
	-- In survival mode, start with length 8
	if gameMode == "survival" then
		snake = {
			{ x = 15, y = 10 }, -- head
			{ x = 14, y = 10 },
			{ x = 13, y = 10 },
			{ x = 12, y = 10 },
			{ x = 11, y = 10 },
			{ x = 10, y = 10 },
			{ x = 9, y = 10 },
			{ x = 8, y = 10 }, -- tail
		}
	else
		snake = {
			{ x = 15, y = 10 }, -- head
			{ x = 14, y = 10 }, -- body
			{ x = 13, y = 10 }, -- tail
		}
	end

	food = { x = 20, y = 10 }
	direction = "right"
	moveTimer = 0
	score = 0
	survivalTimer = 0
	comboCount = 0
	gameOver = false
	paused = false
	foodTimer = 0
	gameOverColorTimer = 0

	-- Set initial speed for survival mode
	if gameMode == "survival" then
		moveDelay = 0.18 -- Start slower in survival mode for easier beginning
	else
		moveDelay = 0.15
	end
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
	survivalTimer = 0 -- Time survived in survival mode (seconds)
	comboCount = 0 -- Combo counter for survival mode speed boosts
	highscoreClassic = 0
	highscoreZen = 0
	highscoreSurvival = 0 -- Stores best time in seconds for survival mode
	gameOver = false
	foodTimer = 0
	gameOverColorTimer = 0
	gameState = "menu"
	selectedMenuOption = 1
	menuOptions = { "Classic Mode", "Zen Mode", "Survival Mode", "Instructions", "Quit" }
	gameMode = "classic"
	instructionPage = 1
	soundsMuted = false
	musicMuted = false

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
		playSound(sounds.ui)
	elseif key == "down" then
		selectedMenuOption = selectedMenuOption + 1
		if selectedMenuOption > #menuOptions then
			selectedMenuOption = 1
		end
		playSound(sounds.ui)
	elseif key == "return" or key == "space" then
		playSound(sounds.ui)
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
			-- Survival Mode
			gameMode = "survival"
			gameState = "playing"
			resetGame()
		elseif selectedMenuOption == 4 then
			-- Instructions
			gameState = "instructions"
		elseif selectedMenuOption == 5 then
			-- Quit
			love.event.quit()
		end
	end
end

local function handleInstructionsInput(key)
	if key == "escape" or key == "return" or key == "space" then
		playSound(sounds.ui)
		instructionPage = 1 -- Reset to first page when exiting
		gameState = "menu"
	elseif key == "left" then
		playSound(sounds.ui)
		instructionPage = instructionPage - 1
		if instructionPage < 1 then
			instructionPage = 3
		end
	elseif key == "right" then
		playSound(sounds.ui)
		instructionPage = instructionPage + 1
		if instructionPage > 3 then
			instructionPage = 1
		end
	end
end

local function handleGameInput(key)
	if gameOver then
		if key == "r" then
			resetGame()
			return
		elseif key == "escape" or key == "return" then
			gameState = "menu"
			playSound(sounds.ui)
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
		playSound(sounds.ui)
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
	-- Global mute controls (work in all states)
	if key == "m" then
		musicMuted = not musicMuted
		if musicMuted then
			sounds.ambiance:pause()
		else
			sounds.ambiance:play()
		end
		return
	elseif key == "s" then
		soundsMuted = not soundsMuted
		if soundsMuted then
			sounds.ambiance:pause()
		elseif not musicMuted then
			sounds.ambiance:play()
		end
		return
	end

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
	-- Check for wall collision (not in zen or survival mode)
	if gameMode ~= "zen" and gameMode ~= "survival" then
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
	-- Survival mode doesn't use this function (speed managed by eating/missing)
	if gameMode == "survival" then
		return
	end

	-- Classic/Zen mode: Adjusted thresholds for new scoring system (up to 5 pts per apple)
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

		-- Wrap around walls in zen and survival mode
		if gameMode == "zen" or gameMode == "survival" then
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
			playSound(sounds.die)
			-- Update survival mode highscore (best time)
			if gameMode == "survival" and survivalTimer > highscoreSurvival then
				highscoreSurvival = survivalTimer
			end
			return
		end

		-- Add new head
		table.insert(snake, 1, newHead)

		-- Check if food was eaten
		if newHead.x == food.x and newHead.y == food.y then
			local pointsEarned
			local r, g, b

			-- In zen mode, always give 1 point and red color
			if gameMode == "zen" then
				pointsEarned = 1
				r, g, b = 1, 0.1, 0.1 -- Red
			elseif gameMode == "survival" then
				-- In survival mode, no points (tracked by time instead)
				pointsEarned = 0
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

			-- Survival mode: eating regains speed (decrease delay by 10%)
			if gameMode == "survival" then
				moveDelay = math.max(0.05, moveDelay * 0.9)
			else
				-- Other modes: update speed based on score
				updateSpeed()
			end

			sounds.eat:setVolume(0.2)
			playSound(sounds.eat)

			-- Update mode-specific high score (survival uses time, updated at game over)
			if gameMode == "zen" then
				if score > highscoreZen then
					highscoreZen = score
				end
			elseif gameMode ~= "survival" then -- Classic mode
				if score > highscoreClassic then
					highscoreClassic = score
				end
			end

			spawnFood()
			-- Snake grows (don't remove tail)
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

	-- Update survival timer
	if gameMode == "survival" then
		survivalTimer = survivalTimer + dt
	end

	-- In survival mode, food disappears after 5 seconds
	if gameMode == "survival" and foodTimer > 5 then
		-- Remove one tail segment when food is missed
		if #snake > 1 then
			table.remove(snake)
			-- Lose speed (increase delay by 25%)
			moveDelay = moveDelay * 1.25

			-- Check if too slow to move (game over)
			if moveDelay > 1.0 then
				gameOver = true
				playSound(sounds.die)
				-- Update survival mode highscore (best time)
				if survivalTimer > highscoreSurvival then
					highscoreSurvival = survivalTimer
				end
			end
		else
			-- Game over if snake has no body left
			gameOver = true
			playSound(sounds.die)
			-- Update survival mode highscore (best time)
			if survivalTimer > highscoreSurvival then
				highscoreSurvival = survivalTimer
			end
		end
		spawnFood()
	end

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

	-- In zen or survival mode, always show red apple
	if gameMode == "zen" or gameMode == "survival" then
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

	local foodX, foodY = gridToPixels(food.x, food.y)

	-- Pulsing glow effect (only in survival mode when decaying)
	if gameMode == "survival" and foodTimer > 4 then
		local time = love.timer.getTime()
		local pulseSpeed = 8
		local pulse = math.abs(math.sin(time * pulseSpeed))
		local glowSize = gridSize + 8 * pulse -- Glow expands and contracts
		local glowAlpha = 0.3 + 0.2 * pulse -- Glow alpha varies

		-- Draw glow (larger, semi-transparent)
		love.graphics.setColor(r, g, b, glowAlpha)
		local glowOffset = (glowSize - gridSize) / 2
		love.graphics.rectangle("fill", foodX - glowOffset, foodY - glowOffset, glowSize, glowSize)
	end

	-- Draw apple (solid) - shrinks when decaying in survival mode
	local appleSize = gridSize
	if gameMode == "survival" and foodTimer > 4 then
		-- Shrink from full size to 0 over the last second
		local shrinkFactor = math.max(0, 1 - (foodTimer - 4))
		appleSize = gridSize * shrinkFactor
	end

	love.graphics.setColor(r, g, b, 1)
	local shrinkOffset = (gridSize - appleSize) / 2
	love.graphics.rectangle("fill", foodX + shrinkOffset, foodY + shrinkOffset, appleSize, appleSize)
	love.graphics.setColor(1, 1, 1, 1)
end

local function drawLCDScore()
	-- In survival mode, display time in MM:SS format
	if gameMode == "survival" then
		local totalSeconds = math.floor(survivalTimer)
		local minutes = math.floor(totalSeconds / 60)
		local seconds = totalSeconds % 60

		-- Format as MMSS (e.g., 0145 for 1:45)
		local timeStr = string.format("%02d%02d", math.min(minutes, 99), seconds)

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

		-- Draw time digits in simple gray
		love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
		for i = 1, 4 do
			local digit = tonumber(timeStr:sub(i, i))
			local digitX = gridToPixels(startGridX + (i - 1) * 4, startGridY)
			lcd.drawDigit(digit, digitX, startY, gridSize)
		end

		love.graphics.setColor(1, 1, 1, 1)
	else
		-- Classic and Zen modes: display score
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
end

local function drawUI()
	love.graphics.setFont(fontSmall)
	local highscoreText
	if gameMode == "zen" then
		highscoreText = "highscore: " .. highscoreZen
	elseif gameMode == "survival" then
		-- Format highscore as MM:SS for survival mode
		local totalSeconds = math.floor(highscoreSurvival)
		local minutes = math.floor(totalSeconds / 60)
		local seconds = totalSeconds % 60
		highscoreText = string.format("best time: %02d:%02d", minutes, seconds)
	else
		highscoreText = "highscore: " .. highscoreClassic
	end
	love.graphics.print(highscoreText, 10, 10)
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
	love.graphics.print(title, (baseWidth - titleWidth) / 2, 20)

	-- Menu options
	love.graphics.setFont(fontMedium)
	local startY = 140
	local spacing = 38

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
	love.graphics.print(hint, (baseWidth - hintWidth) / 2, baseHeight - 25)

	love.graphics.setColor(1, 1, 1, 1)
end

local function drawInstructions()
	love.graphics.setColor(1, 1, 1, 1)
	local lineHeight = 16
	local leftMargin = 40
	local startY = 85

	if instructionPage == 1 then
		-- Page 1: Controls & Classic Mode
		love.graphics.setFont(fontLarge)
		love.graphics.print("CLASSIC MODE", leftMargin, 20)

		love.graphics.setFont(fontSmall)
		local currentY = startY

		-- Controls
		love.graphics.print("CONTROLS:", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Arrow Keys - Move", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("P - Pause  |  R - Restart  |  ESC - Menu", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("M - Mute Music  |  S - Mute All Sounds", leftMargin, currentY)
		currentY = currentY + lineHeight + 15

		-- Rules
		love.graphics.print("RULES:", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Apple ripeness matters! Timing is the key.", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Walls are deadly. Avoid hitting yourself!", leftMargin, currentY)
		currentY = currentY + lineHeight + 10

		-- Apple Legend
		love.graphics.print("APPLE RIPENESS:", leftMargin, currentY)
		currentY = currentY + lineHeight

		local appleData = {
			{ color = { 0.4, 1, 0.2 }, text = "3 pts (unripe)" },
			{ color = { 1, 0.1, 0.1 }, text = "5 pts (perfect!)" },
			{ color = { 0.7, 0.1, 0.3 }, text = "2 pts (overripe)" },
			{ color = { 0.6, 0.3, 0.1 }, text = "1 pt (rotten)" },
			{ color = { 0.6, 0.2, 0.6 }, text = "-1 pt (toxic!)" },
		}

		local squareSize = 8
		for i, apple in ipairs(appleData) do
			local y = currentY + (i - 1) * lineHeight
			love.graphics.setColor(apple.color[1], apple.color[2], apple.color[3], 1)
			love.graphics.rectangle("fill", leftMargin, y + 3, squareSize, squareSize)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(apple.text, leftMargin + 12, y)
		end

		currentY = currentY + #appleData * lineHeight
		love.graphics.setColor(0.8, 0.8, 0.8, 1)
		love.graphics.print("Apples change color over time!", leftMargin, currentY)
	elseif instructionPage == 2 then
		-- Page 2: Zen Mode
		love.graphics.setFont(fontLarge)
		love.graphics.print("ZEN MODE", leftMargin, 20)

		love.graphics.setFont(fontSmall)
		local currentY = startY

		-- Controls
		love.graphics.print("CONTROLS:", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Arrow Keys - Move", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("P - Pause  |  R - Restart  |  ESC - Menu", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("M - Mute Music  |  S - Mute All Sounds", leftMargin, currentY)
		currentY = currentY + lineHeight + 15

		love.graphics.print("Relax and flow...", leftMargin, currentY)
		currentY = currentY + lineHeight + 10

		love.graphics.print("FEATURES:", leftMargin, currentY)
		currentY = currentY + lineHeight

		love.graphics.print("Pass through walls", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Wrap around to the other side", leftMargin, currentY)
		currentY = currentY + lineHeight + 8

		love.graphics.print("Red apples only", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("No ripeness timing needed", leftMargin, currentY)
		currentY = currentY + lineHeight + 8

		love.graphics.print("Always 1 point per apple", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Simple and stress-free", leftMargin, currentY)
	elseif instructionPage == 3 then
		-- Page 3: Survival Mode
		love.graphics.setFont(fontLarge)
		love.graphics.print("SURVIVAL MODE", leftMargin, 20)

		love.graphics.setFont(fontSmall)
		local currentY = startY

		-- Controls
		love.graphics.print("CONTROLS:", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("Arrow Keys - Move", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("P - Pause  |  R - Restart  |  ESC - Menu", leftMargin, currentY)
		currentY = currentY + lineHeight
		love.graphics.print("M - Mute Music  |  S - Mute All Sounds", leftMargin, currentY)
		currentY = currentY + lineHeight + 15

		love.graphics.print("How long can you last?", leftMargin, currentY)
		currentY = currentY + lineHeight + 10

		love.graphics.print("MECHANICS:", leftMargin, currentY)
		currentY = currentY + lineHeight

		love.graphics.print("Apples vanish over time", leftMargin, currentY)
		currentY = currentY + lineHeight + 10

		love.graphics.print("Eat apples to stay fast", leftMargin, currentY)
		currentY = currentY + lineHeight + 10

		love.graphics.print("Slow down too much and you die", leftMargin, currentY)
		currentY = currentY + lineHeight + 10

		love.graphics.print("Keep eating to survive!", leftMargin, currentY)
	end

	-- Page indicator and navigation hint
	love.graphics.setColor(0.5, 0.5, 0.5, 1)
	local pageText = instructionPage .. " / 3"
	local pageWidth = fontSmall:getWidth(pageText)
	love.graphics.print(pageText, (baseWidth - pageWidth) / 2, baseHeight - 40)

	local hint = "LEFT/RIGHT • ENTER/ESC to return"
	local hintWidth = fontSmall:getWidth(hint)
	love.graphics.print(hint, (baseWidth - hintWidth) / 2, baseHeight - 22)

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

	-- Draw game border (not in zen or survival mode during gameplay)
	if gameState ~= "playing" or (gameMode ~= "zen" and gameMode ~= "survival") then
		love.graphics.setColor(0.3, 0.3, 0.3)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", 0, 0, baseWidth, baseHeight)
	end

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

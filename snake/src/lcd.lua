-- ============================================================================
-- LCD Display Module
-- Provides 7-segment style digit and letter patterns and drawing functions
-- ============================================================================

local lcd = {}

-- LCD 7-segment patterns for digits (3x5 grid for each digit)
-- Each digit is represented as a table of {x, y} coordinates relative to digit origin
lcd.digits = {
	[0] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 3, 3 }, -- middle sides
		{ 1, 4 },
		{ 3, 4 }, -- lower sides
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	[1] = {
		{ 3, 1 },
		{ 3, 2 },
		{ 3, 3 },
		{ 3, 4 },
		{ 3, 5 }, -- right side
	},
	[2] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 3, 2 }, -- upper right
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 1, 4 }, -- lower left
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	[3] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 3, 2 }, -- upper right
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 3, 4 }, -- lower right
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	[4] = {
		{ 1, 1 },
		{ 3, 1 }, -- top corners
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 3, 4 },
		{ 3, 5 }, -- right side
	},
	[5] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 }, -- upper left
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 3, 4 }, -- lower right
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	[6] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 }, -- upper left
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 1, 4 },
		{ 3, 4 }, -- lower sides
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	[7] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 3, 2 },
		{ 3, 3 },
		{ 3, 4 },
		{ 3, 5 }, -- right side
	},
	[8] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 1, 4 },
		{ 3, 4 }, -- lower sides
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	[9] = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 3, 4 }, -- lower right
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
}

-- LCD letter patterns (3x5 grid for each letter)
lcd.letters = {
	G = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 }, -- left side
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle with right
		{ 1, 4 },
		{ 3, 4 }, -- sides
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	A = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 1, 4 },
		{ 3, 4 }, -- lower sides
		{ 1, 5 },
		{ 3, 5 }, -- bottom corners
	},
	M = {
		{ 1, 1 },
		{ 1, 2 },
		{ 1, 3 },
		{ 1, 4 },
		{ 1, 5 }, -- left side
		{ 2, 2 }, -- left peak
		{ 3, 1 },
		{ 3, 2 },
		{ 3, 3 },
		{ 3, 4 },
		{ 3, 5 }, -- right side
	},
	E = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 }, -- left
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 1, 4 }, -- left
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	O = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 3, 3 }, -- middle sides
		{ 1, 4 },
		{ 3, 4 }, -- lower sides
		{ 1, 5 },
		{ 2, 5 },
		{ 3, 5 }, -- bottom
	},
	V = {
		{ 1, 1 },
		{ 1, 2 },
		{ 1, 3 },
		{ 1, 4 }, -- left side
		{ 2, 5 }, -- bottom center
		{ 3, 1 },
		{ 3, 2 },
		{ 3, 3 },
		{ 3, 4 }, -- right side
	},
	R = {
		{ 1, 1 },
		{ 2, 1 },
		{ 3, 1 }, -- top
		{ 1, 2 },
		{ 3, 2 }, -- upper sides
		{ 1, 3 },
		{ 2, 3 },
		{ 3, 3 }, -- middle
		{ 1, 4 },
		{ 3, 4 }, -- lower sides
		{ 1, 5 },
		{ 3, 5 }, -- bottom corners
	},
}

-- Draw a single LCD digit at the specified position
-- gridSize: size of each grid cell in pixels
-- startX, startY: top-left position in pixels
function lcd.drawDigit(digit, startX, startY, gridSize)
	local pattern = lcd.digits[digit]
	if pattern then
		for _, coord in ipairs(pattern) do
			local pixelX = startX + (coord[1] - 1) * gridSize
			local pixelY = startY + (coord[2] - 1) * gridSize
			love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
		end
	end
end

-- Draw a single LCD letter at the specified position
-- gridSize: size of each grid cell in pixels
-- startX, startY: top-left position in pixels
function lcd.drawLetter(letter, startX, startY, gridSize)
	local pattern = lcd.letters[letter]
	if pattern then
		for _, coord in ipairs(pattern) do
			local pixelX = startX + (coord[1] - 1) * gridSize
			local pixelY = startY + (coord[2] - 1) * gridSize
			love.graphics.rectangle("fill", pixelX, pixelY, gridSize, gridSize)
		end
	end
end

-- Draw LCD text (string of letters)
-- gridSize: size of each grid cell in pixels
-- startX, startY: top-left position in pixels
function lcd.drawText(text, startX, startY, gridSize)
	local currentX = startX
	for i = 1, #text do
		local char = text:sub(i, i)
		if char ~= " " then
			lcd.drawLetter(char, currentX, startY, gridSize)
		end
		-- Move to next character position (3 cells width + 1 cell spacing)
		currentX = currentX + 4 * gridSize
	end
end

return lcd

love = love
local windowWidth = love.graphics.getWidth()
local windowHeight = love.graphics.getHeight()

local player

function love.load()
	player = {
		x = 400,
		y = 300,
		size = 50,
		speed = 200,
		color = { 1, 0, 0, 1 },
	}
end

function love.update(dt)
	if love.keyboard.isDown("right") then
		player.x = player.x + player.speed * dt
	end
	if love.keyboard.isDown("left") then
		player.x = player.x - player.speed * dt
	end
	if love.keyboard.isDown("down") then
		player.y = player.y + player.speed * dt
	end
	if love.keyboard.isDown("up") then
		player.y = player.y - player.speed * dt
	end
	if player.x < 0 then
		player.x = 0
	end
	if player.x + player.size > windowWidth then
		player.x = windowWidth - player.size
	end
	if player.y < 0 then
		player.y = 0
	end
	if player.y + player.size > windowHeight then
		player.y = windowHeight - player.size
	end
end

function love.keypressed(key)
	if key == "space" then
		player.color = { math.random(), math.random(), math.random(), 1 }
	end
end

function love.draw()
	love.graphics.setColor(player.color[1], player.color[2], player.color[3], 1)
	love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
end

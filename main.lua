require 'utils.class'
require 'utils.table2'

depressed = {}

Object = class(
	function(self, x, y, w, h)
		self.x = x or 0
		self.y = y or 0
		self.w = w or 0
		self.h = h or 0
	end
)

Actor = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.collides = true
	end
)

Player = class(Actor,
	function(self, ...)
		Actor.init(self, ...)
		self.w = 30
		self.h = 30
	end
)

Camera = class(Object,
	function(self, state, ...)
		Object.init(self, ...)
		self.state = state
		self.w = love.window.getWidth()
		self.h = love.window.getHeight()
	end
)

Tree = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.collides = true
		self.w = 32
		self.h = 32
	end
)

World = class(
	function(self)
		self.unitSize = 128
		self.tiles = {}

		self.cells = {}

		self.w = 200
		self.h = 200
	end
)

function World:generate()
	local noise = 0
	local tile
	local cw, ch, cx, cy, tx, ty
	local us = self.unitSize

	cw = math.ceil(800 / us)
	ch = math.ceil(600 / us)

	for y = 1, self.h do
		cy = math.floor(y / ch) + 1
		ty = y * us

		for x = 1, self.w do
			cx = math.floor(x / cw) + 1
			noise = octaveNoise(x, y, 6, 0.88, 0.010)
			tx = x * us

			if noise > 0.500 then
				tile = Tree(
					tx + math.random(1, us * 0.75),
					ty + math.random(1, us * 0.75)
				)
			end

			if not self.cells[cy] then self.cells[cy] = {} end
			if not self.cells[cy][cx] then self.cells[cy][cx] = {} end

			table.insert(self.cells[cy][cx], tile)
		end
	end
end

Game = class(
	function(self)
		self.world = World()
		self.world:generate()

		self.player = Player(500, 500)
	end
)

function intersects(a, b)
	return not (b.x >= (a.x + a.w)
		or (b.x + b.w <= a.x)
		or (b.y >= a.y + a.h)
		or (b.y + b.h <= a.y))
end

function octaveNoise(x, y, octaves, p, scale)
	local total = 0
	local freq = scale
	local amp = 1
	local maxAmp = 0

	for c = 1, octaves do
		total = total + (love.math.noise(x * freq, y * freq) * amp)
		freq = freq * 2
		maxAmp = maxAmp + amp
		amp = amp * p
	end

	return total / maxAmp
end

function love.load()
	math.randomseed(1)
	intrepid = Game()
	camera = Camera(0, 0)
	love.graphics.setBackgroundColor(250, 250, 250)
	love.graphics.setColor(40, 180, 60)
end

function love.draw()
	local count = 0

	--[[ Grid rendering
	local ax = math.floor(camera.x / world.unitSize)
	local ay = math.floor(camera.y / world.unitSize)
	if ax == 0 then ax = 1 end
	if ay == 0 then ay = 1 end

	local bx = ax + math.ceil(camera.w / world.unitSize)
	local by = ay + math.ceil(camera.h / world.unitSize)
	if bx > world.w then
		bx = world.w
	end
	if by > world.h then
		by = world.h
	end

	love.graphics.setColor(80, 200, 80)
	for y = ay, by do
		for x = ax, bx do
			local tile = world.tiles[y][x]
			if tile then
				love.graphics.rectangle("fill",
					tile.x - camera.x,
					tile.y - camera.y,
					tile.w,
					tile.h
				)
				count = count + 1
			end
		end
	end
	]]--

	-- Partition rendering
	local neighbors = {
		{x =1,y =1},
		{x=0,y =1},
		{x=1,y=1},
		{x=1,y=0},
		{x=1,y=1},
		{x=0,y=1},
		{x=1,y =1},
		{x=0,y=-1},
		{x=0,y=0}
	}

	local cellWidth, cellHeight, cellX, cellY, neighborX, neighborY
	local world = intrepid.world
	local cells = world.cells

	cellWidth = math.ceil(800 / world.unitSize)
	cellHeight = math.ceil(600 / world.unitSize)

	cellX = math.floor((camera.x / world.unitSize) / cellWidth) + 1
	cellY = math.floor((camera.y / world.unitSize) / cellHeight) + 1

	love.graphics.setColor(80, 200, 80)
	for k, of in ipairs(neighbors) do
		neighborX = cellX + of.x
		neighborY = cellY + of.y
		if cells[neighborY] and cells[neighborY][neighborX] then

			for i, t in ipairs(cells[neighborY][neighborX]) do
				if t.x > camera.x
					and t.y > camera.y
					and t.x < camera.x + camera.w
					and t.y < camera.y + camera.h
				then
					love.graphics.rectangle("fill",
						t.x - camera.x,
						t.y - camera.y,
						t.w,
						t.h
					)
					count = count + 1
				end
			end
		end
	end

	love.graphics.setColor(60, 60, 180)
	love.graphics.rectangle("fill",
		intrepid.player.x - camera.x,
		intrepid.player.y - camera.y,
		intrepid.player.w,
		intrepid.player.h
	)

	love.graphics.setColor(0, 0, 0)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
	love.graphics.print("Rects: " .. count, 10, 30)
end

function love.update(dt)
	local player = intrepid.player
	if depressed["escape"] then
		love.event.quit()
	end

	local vectors = {
		w = {x=0,y=-1},
		a = {x=-1,y=0},
		s = {x=0,y=1},
		d = {x=1,y=0}
	}

	for key in pairs(depressed) do
		if not vectors[key] then break end

		player.x = player.x + vectors[key].x
		player.y = player.y + vectors[key].y

		local neighbors = {
			{x =1,y =1},
			{x=0,y =1},
			{x=1,y=1},
			{x=1,y=0},
			{x=1,y=1},
			{x=0,y=1},
			{x=1,y =1},
			{x=0,y=-1},
			{x=0,y=0}
		}

		local cw, ch, cx, cy, nx, ny
		local world = intrepid.world
		local cells = world.cells

		cw = math.ceil(800 / world.unitSize)
		ch = math.ceil(600 / world.unitSize)

		cx = math.floor((camera.x / world.unitSize) / cw) + 1
		cy = math.floor((camera.y / world.unitSize) / ch) + 1

		for i, of in ipairs(neighbors) do
			nx = cx + of.x
			ny = cy + of.y
			if cells[ny] and cells[ny][nx] then
				for i, t in ipairs(cells[ny][nx]) do
					if t.x > camera.x
						and t.y > camera.y
						and t.x < camera.x + camera.w
						and t.y < camera.y + camera.h
						and intersects(player, t)
					then
						if key == "w" then
							player.y = t.y + t.h
						end
						if key == "a" then
							player.x = t.x + t.w
						end
						if key == "s" then
							player.y = t.y - player.h
						end
						if key == "d" then
							player.x = t.x - player.w
						end
					end
				end
			end
		end
	end

	camera.x = player.x - (love.window.getWidth() / 2)
	camera.y = player.y - (love.window.getHeight() / 2)

	if camera.x < 0 then camera.x = 0 end
	if camera.y < 0 then camera.y = 0 end
end

function love.run()

	if love.math then
		love.math.setRandomSeed(os.time())
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end

	if love.timer then love.timer.step() end

	local dt = 0
	local updates = 1 / 60
	local accumulator = 0.0

	while true do
		if love.event then
			love.event.pump()
			for e,a,b,c,d in love.event.poll() do
				if e == "quit" then
					if not love.quit or not love.quit() then
						if love.audio then
							love.audio.stop()
						end
						return
					end
				end
				love.handlers[e](a,b,c,d)
			end
		end

		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end

		if dt > 0.25 then
			dt = 0.25
		end

		accumulator = accumulator + dt
		while accumulator >= updates do
			if love.update then love.update(dt) end
			accumulator = accumulator - updates
		end

		if love.window and love.graphics and love.window.isCreated() then
			love.graphics.clear()
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end
	end
end

function love.keypressed(key, unicode)
	depressed[key] = true
end

function love.keyreleased(key, unicode)
	depressed[key] = nil
end

require 'utils.class'
require 'utils.table2'
require 'utils.vec2'

depressed = {}

Object = class(
	function(self, x, y, w, h)
		self.x = x or 0
		self.y = y or 0
		self.w = w or 0
		self.h = h or 0
	end
)

Camera = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.w = 800
		self.h = 600
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
		self.unitSize = 32
		self.cellWidth = 26
		self.cellHeight = 20
		self.cells = {}
		self.w = 500
		self.h = 500
	end
)

function World:neighbors(a)
	local result = {}
	local neighbors = {
		{x = -1, y = -1},
		{x = -1, y = 0},
		{x = -1, y = 1},
		{x = 0, y = -1},
		{x = 0, y = 0},
		{x = 0, y = 1},
		{x = 1, y = -1},
		{x = 1, y = 0},
		{x = 1, y = 1}
	}
	for k, v in ipairs(neighbors) do
		if self.cells[a.y+v.y] and self.cells[a.y+v.y][a.x+v.x] then
			table.insert(result, self.cells[a.y+v.y][a.x+v.x])
		end
	end
	return result
end

function World:generate()
	for y = 1, self.h do
		for x = 1, self.w do
			v = octaveNoise(x, y, 6, 0.88, 0.010)
			if v > 0.500 then
				o = Tree(x * self.unitSize, y * self.unitSize)
			end
			cy = math.floor(y / self.cellHeight) + 1
			cx = math.floor(x / self.cellWidth) + 1
			if not self.cells[cy] then
				self.cells[cy] = {}
			end
			if not self.cells[cy][cx] then
				self.cells[cy][cx] = {}
			end
			if o then
				table.insert(self.cells[cy][cx], o)
			end
		end
	end
end

function World:unitToCell(x, y)
	return {
		x = math.floor(x / self.cellWidth),
		y = math.floor(y / self.cellHeight)
	}
end

function World:pixelToUnit(x, y)

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

function intersects(a, b)
	return (math.abs(a.x - b.x) * 2 < (a.w + b.w))
		and (math.abs(a.y - b.y) * 2 < (a.h + b.h))
end

function love.load()
	world = World()
	world:generate()
	camera = Camera(0, 0)
	love.graphics.setBackgroundColor(235, 235, 235)
	love.graphics.setColor(40, 180, 60)
end

function love.draw()
	local cx = math.floor((camera.x / world.unitSize) / world.cellWidth) + 1
	local cy = math.floor((camera.y / world.unitSize) / world.cellHeight) + 1
	local neighbors = world:neighbors({x=cx, y=cy})
	for k, n in ipairs(neighbors) do
		for i, tile in ipairs(n) do
			love.graphics.rectangle("fill",
				tile.x - camera.x, tile.y - camera.y,
				tile.w, tile.h
			)
		end
	end
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end

function love.update(dt)
	if depressed["escape"] then
		love.event.quit()
	end
	if depressed["w"] then
		camera.y = camera.y -10
	end
	if depressed["a"] then
		camera.x = camera.x - 10
	end
	if depressed["s"] then
		camera.y = camera.y + 10
	end
	if depressed["d"] then
		camera.x = camera.x + 10
	end
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
	depressed[key] = false
end

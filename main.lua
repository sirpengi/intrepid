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
	end
)

Tree = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.collides = true
		self.w = 2
		self.h = 2
	end
)

World = class(
	function(self)
		self.cellSize = 2
		self.tiles = {}
		self.w = 400
		self.h = 300
	end
)

function World:generate()
	for y = 1, self.h do
		for x = 1, self.w do
			v = octaveNoise(x, y, 6, 0.88, 0.010)
			if v > 0.500 and v < 1 then
				o = Tree(x * self.cellSize, y * self.cellSize)
			end
			table.insert(self.tiles, o)
		end
	end
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
	love.graphics.setBackgroundColor(235, 235, 235)
	love.graphics.setColor(40, 180, 60)
end

function love.draw()
	for i, tile in ipairs(world.tiles) do
		love.graphics.rectangle("fill",
			tile.x,
			tile.y,
			tile.w,
			tile.h
		)
	end
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end

function love.update(dt)
	if depressed["escape"] then
		love.event.quit()
	end
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

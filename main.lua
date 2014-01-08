require 'utils.class'
require 'utils.table2'
require 'utils.vec2'

depressed = {}

Game = class(
	function(self)
		self.world = World()
		self.world:generate()
	end
)

Object = class(
	function(self, x, y, w, h)
		self.x = x or 0
		self.y = y or 0
		self.w = w or 0
		self.h = h or 0
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
		self.unitSize = 32
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

	cw = math.ceil(800 / self.unitSize)
	ch = math.ceil(600 / self.unitSize)

	for y = 1, self.h do
		cy = math.floor(y / ch) + 1
		ty = y * self.unitSize

		for x = 1, self.w do
			cx = math.floor(x / cw) + 1
			noise = octaveNoise(x, y, 6, 0.88, 0.010)
			tx = x * self.unitSize

			if noise > 0.500 then
				tile = Tree(tx, ty)
			end

			if not self.cells[cy] then self.cells[cy] = {} end
			if not self.cells[cy][cx] then self.cells[cy][cx] = {} end

			table.insert(self.cells[cy][cx], tile)
		end
	end
end

function World:neighbors(x, y)

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
	love.graphics.setBackgroundColor(235, 235, 235)
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
	local cw, ch, cx, cy
	cw = math.ceil(800 / intrepid.world.unitSize)
	ch = math.ceil(600 / intrepid.world.unitSize)

	cx = math.floor((camera.x / intrepid.world.unitSize) / cw) + 1
	cy = math.floor((camera.y / intrepid.world.unitSize) / ch) + 1

	love.graphics.setColor(80, 200, 80)
	for i, t in ipairs(intrepid.world.cells[cy][cx]) do
		if t.x > camera.x 
			and t.y > camera.y 
			and t.x < camera.x + camera.w 
			and t.y < camera.y + camera.h then

			love.graphics.rectangle("fill",
				t.x - camera.x,
				t.y - camera.y,
				t.w,
				t.h
			)

			count = count + 1
		end
	end

	love.graphics.setColor(0, 0, 0)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
	love.graphics.print("Rects: " .. count, 10, 30)
end

function love.update(dt)
	if depressed["escape"] then
		love.event.quit()
	end
	if depressed["w"] then
		camera.y = camera.y -1
	end
	if depressed["a"] then
		camera.x = camera.x - 1
	end
	if depressed["s"] then
		camera.y = camera.y + 1
	end
	if depressed["d"] then
		camera.x = camera.x + 1
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

			accumulator = accumulator - updates
		end
		if love.update then love.update(dt) end

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

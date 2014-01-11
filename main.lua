require 'utils.class'
require 'utils.table2'
require 'utils.collections.spatial-hash'

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
		self.lastX = 0
		self.lastY = 0
	end
)

function Actor:push(x, y)
	self.x = self.x + x
	self.y = self.y + y
end

function Actor:move(x, y)
	if x then self.x = x end
	if y then self.y = y end
end

Player = class(Actor,
	function(self, ...)
		Actor.init(self, ...)
		self.w = 32
		self.h = 32
	end
)

Camera = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.w = love.window.getWidth()
		self.h = love.window.getHeight()
	end
)

function Camera:set(x, y)
	self.x = math.max(0, x)
	self.y = math.max(0, y)
end

function Camera:center(x, y, w, h)
	local cx = x - (love.window.getWidth() / 2) + (w / 2)
	local cy = y - (love.window.getHeight() / 2) + (h / 2)
	self:set(cx, cy)
end

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
		self.objects = SpatialHash(800)
		self.w = 400
		self.h = 200
	end
)

function World:generate()
	local n = 0
	local t = nil
	local x, y = 0
	for c = 1, self.h do
		y = c * self.unitSize
		for r = 1, self.w do
			x = r * self.unitSize
			n = octaveNoise(c, r, 6, 0.88, 0.010)
			if n > 0.500 then
				t = Tree(x, y)
			end
			self.objects:hash(x, y, t)
			t = nil
		end
	end
end

Game = class(
	function(self)
		self.world = nil
		self.player = nil
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
	love.graphics.setBackgroundColor(240, 240, 240)

	camera = Camera(0, 0)
	player = Player(400, 400)
	world = World()
	world:generate()

	intrepid = Game()
	intrepid.world = world
	intrepid.player = player
end

function love.draw()
	local count = 0
	local tiles = {}

	love.graphics.setColor(20, 70, 20)
	tiles = world.objects:contents(camera.x, camera.y, 1)
	for i, t in ipairs(tiles) do
		love.graphics.rectangle("fill",
			t.x - camera.x,
			t.y - camera.y,
			t.w,
			t.h
		)
		count = count + 1
	end

	love.graphics.setColor(90, 90, 90)
	love.graphics.rectangle("fill",
		player.x - camera.x,
		player.y - camera.y,
		player.w,
		player.h
	)

	love.graphics.print("FPS " .. love.timer.getFPS(), 10, 10)
	love.graphics.print("Tiles in buckets " .. #tiles, 10, 30)
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
		if not vectors[key] then
			break
		end
		player:push(vectors[key].x, vectors[key].y)
	end

	camera:center(player.x, player.y, player.w, player.h)
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

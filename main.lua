require 'utils.class'
require 'utils.collections.spatial-hash'

UNIT_SIZE = 32
DEPRESSED = {}

function intersects(a, b)
	return not (b.x >= (a.x + a.w)
		or (b.x + b.w <= a.x)
		or (b.y >= a.y + a.h)
		or (b.y + b.h <= a.y))
end

function noise(x, y, octaves, persistence, scale)
	local total = 0
	local freq = scale
	local amp = 1
	local maxAmp = 0

	for c = 1, octaves do
		total = total + (love.math.noise(x * freq, y * freq) * amp)
		freq = freq * 2
		maxAmp = maxAmp + amp
		amp = amp * persistence
	end

	return total / maxAmp
end

Object = class(
	function(self, x, y, w, h)
		self.x = x or 0
		self.y = y or 0
		self.w = w or UNIT_SIZE
		self.h = h or UNIT_SIZE
		self.color = {255, 0, 255}
	end
)

Tree = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.w = UNIT_SIZE
		self.h = UNIT_SIZE
		self.color = {150, 150, 150}
		self.collides = true
	end
)

Actor = class(Object,
	function(self, ...)
		Object.init(self, ...)
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
		self.color = {60, 60, 60}
		self.w = UNIT_SIZE * 0.80
		self.h = UNIT_SIZE * 0.80
	end
)

Camera = class(Object,
	function(self, ...)
		Object.init(self, ...)
		self.w = love.window.getWidth()
		self.h = love.window.getHeight()
	end
)

function Camera:isVisible(x, y, w, h)
	return self.x < x + w
		and self.y < y + h
		and self.x + self.w > x
		and self.y + self.h > y
end

function Camera:set(x, y)
	self.x = math.max(0, x)
	self.y = math.max(0, y)
end

function Camera:center(x, y, w, h)
	local cx = x - (love.window.getWidth() / 2) + (w / 2)
	local cy = y - (love.window.getHeight() / 2) + (h / 2)
	self:set(cx, cy)
end

World = class(
	function(self)
		UNIT_SIZE = UNIT_SIZE
		self.objects = SpatialHash(800)
		self.w = 400
		self.h = 400
	end
)

function World:generate()
	local n = 0
	local t = nil
	local x, y = 0
	for c = 1, self.h, 3 do
		for r = 1, self.w, 3 do

			-- determine tree density
			n = noise(c, r, 5, 0.5, 0.006)
			if n < 1 and n > 0.75 then
				p = 1
			elseif n < 0.75 and n > 0.6 then
				p = 0.45
			elseif n < 0.6 and n > 0.5 then
				p = 0.25
			else
				p = 0
			end

			if love.math.random() < p then
				y = (c * UNIT_SIZE) + love.math.random(0, UNIT_SIZE * 2)
				x = (r * UNIT_SIZE) + love.math.random(0, UNIT_SIZE * 2)
				t = Tree(x, y)
				self.objects:hash(x, y, t)
			end
		end
	end
end

Game = class(
	function(self)
		self.world = nil
		self.player = nil
	end
)

function love.load()
	tree = love.graphics.newImage("tree.png")
	snow = love.graphics.newImage("snow.jpg")
	love.graphics.setBackgroundColor(240, 240, 240)

	camera = Camera(0, 0)
	player = Player(0, 0)
	world = World()
	world:generate()

	intrepid = Game()
	intrepid.world = world
	intrepid.player = player
end

function love.draw()
	local count = 0

	love.graphics.setColor(unpack(player.color))
	love.graphics.rectangle("fill",
		player.x - camera.x,
		player.y - camera.y,
		player.w,
		player.h
	)


	love.graphics.setColor(160, 160, 160)
	tiles = world.objects:items(player.x, player.y, 1)
	for i, t in ipairs(tiles) do
		if camera:isVisible(t.x, t.y, 60, 125) then
			love.graphics.draw(
				tree,
				t.x - camera.x,
				t.y - camera.y,
				0,
				1.5,
				1.8,
				21,
				82
			)
			count = count + 1
		end
	end

	love.graphics.setColor(0, 0, 0)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
	love.graphics.print("Objects drawn:  " .. count, 10, 30)
	love.graphics.print("Objects in buckets: " .. #tiles, 10, 50)
end

function love.update(dt)
	local player = intrepid.player

	if DEPRESSED["escape"] then
		love.event.quit()
	end

	local vectors = {
		w = {x=0,y=-5},
		a = {x=-5,y=0},
		s = {x=0,y=5},
		d = {x=5,y=0}
	}

	for key in pairs(DEPRESSED) do
		if not vectors[key] then
			break
		end

		player:push(vectors[key].x, vectors[key].y)

		-- collision
		nearby = world.objects:items(player.x, player.y, 1)
		for i, t in ipairs(nearby) do
			if camera:isVisible(t.x, t.y, t.w, t.h)
				and intersects(player, t)
				and t.collides
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
	DEPRESSED[key] = true
end

function love.keyreleased(key, unicode)
	DEPRESSED[key] = nil
end

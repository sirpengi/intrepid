require 'utils.class'
require 'utils.table2'

SpatialHash = class(
	function(self, size)
		self.buckets = nil
		self.size = size
	end
)

function SpatialHash:_set(c, r, v)
	assert(c > 0 or r > 0, "Index less than 1")
	self:_expand(c, r)
	table.insert(self.buckets[c][r], v)
end

function SpatialHash:_expand(c, r)
	if not self.buckets then
		self.buckets = {}
	end

	if not self.buckets[c] then
		for x = #self.buckets + 1, c do
			self.buckets[x] = {}
		end
	end

	if not self.buckets[c][r] then
		for y = #self.buckets[c] + 1, r do
			self.buckets[c][y] = {}
		end
	end
end

function SpatialHash:init(w, h)
	self.buckets = {}
	for c = 1, w do
		if not self.buckets[c] then
			self.buckets[c] = {}
		end
		for r = 1, h do
			self.buckets[c][r] = {}
		end
	end
end

function SpatialHash:hash(x, y, v)
	c = math.floor(x / self.size) + 1
	r = math.floor(y / self.size) + 1

	if v then
		self:_set(c, r, v)
	end

	return c, r
end

function SpatialHash:bucket(x, y)
	local c, r = self:hash(x, y)
	if self.buckets[c] and self.buckets[c][r] then
		return self.buckets[c][r]
	end
	return nil
end

function SpatialHash:contents(x, y, radius)
	local items = {}
	local c, r = self:hash(x, y)
	local nc, nr

	for a = -radius, radius do
		nc = c + a
		for b = -radius, radius do
			nr = r + b
			if self.buckets[nc] and self.buckets[nc][nr] then
				for i, item in ipairs(self.buckets[nc][nr]) do
					table.insert(items, item)
				end
			end
		end
	end

	return items
end

function SpatialHash:clear()
	self:init(self.getWidth(), self.getHeight())
end

function SpatialHash:getWidth()
	return #self.buckets
end

function SpatialHash:getHeight()
	if self.buckets[1] then
		return #self.buckets[1]
	else
		return nil
	end
end

Vec = class(
    function(self, x, y)
        self.x = x or 0
        self.y = y or 0
    end
)

function Vec:scale(d, r, v)
    return (((r.y - r.x) * (v - d.x)) / d.y - d.x) + r.x
end

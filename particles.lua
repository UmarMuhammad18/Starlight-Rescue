local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({}, Particles)
    self.list = {}
    return self
end

function Particles:spawn(x, y, opts)
    opts = opts or {}
    local count = opts.count or 10
    local speed = opts.speed or 120
    local life = opts.life or 0.6
    local color = opts.color or {1, 1, 1, 1}
    local size = opts.size or 3

    for i = 1, count do
        local angle = love.math.random() * math.pi * 2
        local spd = speed * (0.4 + love.math.random() * 0.8)
        table.insert(self.list, {
            x = x,
            y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = life * (0.6 + love.math.random() * 0.5),
            maxLife = life,
            size = size * (0.6 + love.math.random() * 0.6),
            color = {color[1], color[2], color[3], color[4] or 1},
            gravity = opts.gravity or 0,
        })
    end
end

function Particles:update(dt)
    for i = #self.list, 1, -1 do
        local p = self.list[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + (p.gravity or 0) * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.list, i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.list) do
        local a = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], a * (p.color[4] or 1))
        love.graphics.circle("fill", p.x, p.y, p.size * a)
    end
end

function Particles:clear()
    self.list = {}
end

return Particles

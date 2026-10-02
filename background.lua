local Config = require("config")
local Background = {}
Background.__index = Background

function Background.new()
    local self = setmetatable({}, Background)
    self.stars = {}
    for i = 1, Config.BG_STAR_COUNT do
        table.insert(self.stars, {
            x = love.math.random() * Config.WINDOW_W,
            y = love.math.random() * Config.WINDOW_H,
            size = love.math.random() * 1.8 + 0.4,
            speed = love.math.random() * 25 + 8,
            alpha = love.math.random() * 0.5 + 0.25,
            layer = love.math.random(1, 3),
        })
    end
    self.nebulaOffset = 0
    return self
end

function Background:update(dt, difficulty)
    difficulty = difficulty or 1
    local speedMul = 1 + (difficulty - 1) * 0.15
    for _, s in ipairs(self.stars) do
        s.y = s.y + s.speed * speedMul * dt * (0.4 + s.layer * 0.3)
        if s.y > Config.WINDOW_H + 5 then
            s.y = -5
            s.x = love.math.random() * Config.WINDOW_W
        end
    end
    self.nebulaOffset = self.nebulaOffset + dt * 8
end

function Background:draw()
    -- deep space
    love.graphics.setColor(Config.COLOR.bg)
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_W, Config.WINDOW_H)

    -- soft nebula bands
    for i = 1, 3 do
        local y = ((self.nebulaOffset * (0.3 + i * 0.15)) % (Config.WINDOW_H + 200)) - 100
        love.graphics.setColor(0.08 + i * 0.02, 0.05, 0.18, 0.12)
        love.graphics.ellipse("fill", Config.WINDOW_W * 0.5, y, Config.WINDOW_W * 0.7, 80 + i * 20)
    end

    -- parallax stars
    for _, s in ipairs(self.stars) do
        love.graphics.setColor(0.85, 0.9, 1.0, s.alpha)
        love.graphics.circle("fill", s.x, s.y, s.size)
    end
end

return Background

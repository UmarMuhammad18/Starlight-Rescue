local Config = require("config")
local Utils = require("utils")

local Star = {}
Star.__index = Star

function Star.new(isPowerup)
    local self = setmetatable({}, Star)
    self.x = love.math.random(30, Config.WINDOW_W - 30)
    self.y = -20
    self.radius = Config.STAR_RADIUS
    self.speed = love.math.random(Config.STAR_SPEED_MIN, Config.STAR_SPEED_MAX)
    self.spin = love.math.random() * math.pi * 2
    self.spinSpeed = (love.math.random() - 0.5) * 6

    if isPowerup then
        self.isPowerup = true
        self.powerType = Utils.randomChoice(Config.POWERUP_TYPES)
        self.radius = 12
    else
        self.isPowerup = false
    end
    return self
end

function Star:update(dt, player)
    self.y = self.y + self.speed * dt
    self.spin = self.spin + self.spinSpeed * dt

    -- magnet pull
    if player.magnet > 0 then
        local d = Utils.dist(self.x, self.y, player.x, player.y)
        if d < 180 then
            local nx, ny = Utils.normalize(player.x - self.x, player.y - self.y)
            local pull = (1 - d / 180) * 280 * dt
            self.x = self.x + nx * pull
            self.y = self.y + ny * pull
        end
    end
end

function Star:draw()
    if self.isPowerup then
        local t = love.timer.getTime()
        local pulse = 0.7 + 0.3 * math.sin(t * 7)
        local colors = {
            shield = {0.3, 0.9, 1.0},
            slow   = {0.6, 0.4, 1.0},
            magnet = {1.0, 0.5, 0.2},
            mult   = {1.0, 0.9, 0.2},
            life   = {0.3, 1.0, 0.5},
        }
        local c = colors[self.powerType] or {1, 1, 1}
        love.graphics.setColor(c[1], c[2], c[3], 0.35 * pulse)
        love.graphics.circle("fill", self.x, self.y, self.radius + 6)
        love.graphics.setColor(c[1], c[2], c[3], 1)
        love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("line", self.x, self.y, self.radius + 2)

        -- letter indicator
        love.graphics.setColor(0, 0, 0, 0.8)
        local label = string.upper(string.sub(self.powerType, 1, 1))
        love.graphics.printf(label, self.x - 8, self.y - 7, 16, "center")
    else
        -- normal star
        love.graphics.setColor(Config.COLOR.starGlow)
        love.graphics.circle("fill", self.x, self.y, self.radius + 4)

        love.graphics.setColor(Config.COLOR.star)
        love.graphics.circle("fill", self.x, self.y, self.radius)

        -- sparkle
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", self.x - 2, self.y - 2, 2.5)
    end
end

return Star

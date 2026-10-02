local Config = require("config")
local Utils = require("utils")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, speed)
    local self = setmetatable({}, Enemy)
    self.x = x or 50
    self.y = y or 50
    self.radius = Config.ENEMY_RADIUS
    self.baseSpeed = speed or Config.ENEMY_BASE_SPEED
    self.speed = self.baseSpeed
    self.wobble = love.math.random() * math.pi * 2
    return self
end

function Enemy:update(dt, player, slowFactor)
    slowFactor = slowFactor or 1
    local dx = player.x - self.x
    local dy = player.y - self.y
    local nx, ny = Utils.normalize(dx, dy)

    -- slight wobble so it feels less robotic
    self.wobble = self.wobble + dt * 3
    local wx = math.cos(self.wobble) * 18
    local wy = math.sin(self.wobble * 1.3) * 12

    self.x = self.x + (nx * self.speed + wx * 0.4) * dt * slowFactor
    self.y = self.y + (ny * self.speed + wy * 0.4) * dt * slowFactor

    self.x = Utils.clamp(self.x, self.radius, Config.WINDOW_W - self.radius)
    self.y = Utils.clamp(self.y, self.radius, Config.WINDOW_H - self.radius)
end

function Enemy:draw()
    -- glow
    love.graphics.setColor(Config.COLOR.enemyGlow)
    love.graphics.rectangle("fill",
        self.x - self.radius - 3, self.y - self.radius - 3,
        (self.radius + 3) * 2, (self.radius + 3) * 2, 6, 6)

    -- body
    love.graphics.setColor(Config.COLOR.enemy)
    love.graphics.rectangle("fill",
        self.x - self.radius, self.y - self.radius,
        self.radius * 2, self.radius * 2, 5, 5)

    -- "eye"
    love.graphics.setColor(1, 0.7, 0.7, 0.9)
    love.graphics.circle("fill", self.x, self.y - 2, 4)
    love.graphics.setColor(0.1, 0.05, 0.05)
    love.graphics.circle("fill", self.x, self.y - 2, 2)
end

return Enemy

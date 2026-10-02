local Config = require("config")
local Utils = require("utils")

local Player = {}
Player.__index = Player

function Player.new()
    local self = setmetatable({}, Player)
    self:reset()
    return self
end

function Player:reset()
    self.x = Config.WINDOW_W / 2
    self.y = Config.WINDOW_H - 70
    self.radius = Config.PLAYER_RADIUS
    self.speed = Config.PLAYER_SPEED
    self.invuln = 0
    self.flash = 0
    self.trail = {}
    self.shield = 0
    self.magnet = 0
    self.slow = 0
    self.mult = 1
    self.multTimer = 0
end

function Player:update(dt)
    -- movement
    local mx, my = 0, 0
    if love.keyboard.isDown("left", "a") then mx = mx - 1 end
    if love.keyboard.isDown("right", "d") then mx = mx + 1 end
    if love.keyboard.isDown("up", "w") then my = my - 1 end
    if love.keyboard.isDown("down", "s") then my = my + 1 end

    -- simple gamepad support (first joystick)
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local j = joysticks[1]
        local jx = j:getAxis(1)
        local jy = j:getAxis(2)
        if math.abs(jx) > 0.2 then mx = mx + jx end
        if math.abs(jy) > 0.2 then my = my + jy end
    end

    mx, my = Utils.normalize(mx, my)
    self.x = self.x + mx * self.speed * dt
    self.y = self.y + my * self.speed * dt

    self.x = Utils.clamp(self.x, self.radius, Config.WINDOW_W - self.radius)
    self.y = Utils.clamp(self.y, self.radius, Config.WINDOW_H - self.radius)

    -- trail
    table.insert(self.trail, 1, {x = self.x, y = self.y, life = 0.35})
    if #self.trail > Config.PLAYER_TRAIL_MAX then
        table.remove(self.trail)
    end
    for i = #self.trail, 1, -1 do
        self.trail[i].life = self.trail[i].life - dt
        if self.trail[i].life <= 0 then table.remove(self.trail, i) end
    end

    -- timers
    if self.invuln > 0 then self.invuln = self.invuln - dt end
    if self.flash > 0 then self.flash = self.flash - dt end
    if self.shield > 0 then self.shield = self.shield - dt end
    if self.magnet > 0 then self.magnet = self.magnet - dt end
    if self.slow > 0 then self.slow = self.slow - dt end
    if self.multTimer > 0 then
        self.multTimer = self.multTimer - dt
        if self.multTimer <= 0 then self.mult = 1 end
    end
end

function Player:takeHit()
    if self.invuln > 0 or self.shield > 0 then
        if self.shield > 0 then
            self.shield = 0
            return false -- absorbed by shield
        end
        return false
    end
    self.invuln = Config.PLAYER_INVULN_TIME
    self.flash = 0.4
    return true -- real hit
end

function Player:draw()
    -- trail
    for i, t in ipairs(self.trail) do
        local a = t.life / 0.35 * 0.35
        love.graphics.setColor(Config.COLOR.player[1], Config.COLOR.player[2], Config.COLOR.player[3], a)
        love.graphics.circle("fill", t.x, t.y, self.radius * (0.4 + 0.3 * a))
    end

    -- invuln blink
    local visible = true
    if self.invuln > 0 then
        visible = math.floor(self.invuln * 12) % 2 == 0
    end

    if visible then
        -- glow
        love.graphics.setColor(Config.COLOR.playerGlow)
        love.graphics.circle("fill", self.x, self.y, self.radius + 6)

        -- body
        love.graphics.setColor(Config.COLOR.player)
        love.graphics.circle("fill", self.x, self.y, self.radius)

        -- highlight
        love.graphics.setColor(1, 1, 0.7, 0.7)
        love.graphics.circle("fill", self.x - 4, self.y - 5, self.radius * 0.35)

        -- shield ring
        if self.shield > 0 then
            local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 8)
            love.graphics.setColor(Config.COLOR.shield[1], Config.COLOR.shield[2], Config.COLOR.shield[3], 0.45 * pulse)
            love.graphics.circle("line", self.x, self.y, self.radius + 10 + pulse * 2)
            love.graphics.setColor(Config.COLOR.shield[1], Config.COLOR.shield[2], Config.COLOR.shield[3], 0.25)
            love.graphics.circle("fill", self.x, self.y, self.radius + 8)
        end
    end
end

return Player

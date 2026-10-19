-- The player's ship

local config = require("src.config")
local util = require("src.util")

local Player = {}

function Player.new()
    local c = config.player
    return {
        x = c.startX, y = c.startY,
        radius = c.radius,
        tilt = 0,
        moving = false,
        invuln = 0,     -- the remaining fields are seconds left on each effect
        shield = 0,
        magnet = 0,
        boost = 0,
    }
end

function Player.update(p, dt, moveX, moveY)
    local speed = config.player.speed
    if p.boost > 0 then speed = speed * config.player.boostMultiplier end

    p.x = util.clamp(p.x + moveX * speed * dt, p.radius, config.width - p.radius)
    p.y = util.clamp(p.y + moveY * speed * dt, p.radius, config.height - p.radius)
    p.moving = moveX ~= 0 or moveY ~= 0

    -- Bank into turns
    p.tilt = util.lerp(p.tilt, moveX * 0.35, math.min(1, dt * 10))

    p.invuln = math.max(0, p.invuln - dt)
    p.shield = math.max(0, p.shield - dt)
    p.magnet = math.max(0, p.magnet - dt)
    p.boost = math.max(0, p.boost - dt)
end

-- Also used by the HUD for the lives display
function Player.drawShip(x, y, scale, rotation, alpha, flameColor)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation)
    love.graphics.scale(scale)

    if flameColor then
        love.graphics.setColor(flameColor[1], flameColor[2], flameColor[3], 0.9 * alpha)
        love.graphics.polygon("fill", -6, 9, 6, 9, 0, 20 + love.math.random() * 8)
    end

    -- Arrowhead hull, filled as two convex halves
    love.graphics.setColor(1, 0.8, 0.2, alpha)
    love.graphics.polygon("fill", 0, -22, 16, 14, 0, 7)
    love.graphics.polygon("fill", 0, -22, 0, 7, -16, 14)
    love.graphics.setColor(1, 1, 0.5, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", 0, -22, 16, 14, 0, 7, -16, 14)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0.3, 0.8, 1, alpha)
    love.graphics.circle("fill", 0, -4, 5)

    love.graphics.pop()
end

function Player.draw(p, time)
    if p.magnet > 0 and util.blinkVisible(p.magnet, 1.5) then
        love.graphics.setColor(0.85, 0.5, 1, 0.2)
        love.graphics.circle("line", p.x, p.y, config.powerups.magnetRange)
    end

    local alpha = 1
    if p.invuln > 0 and math.floor(p.invuln * 12) % 2 == 0 then alpha = 0.25 end

    local flame
    if p.moving then
        flame = p.boost > 0 and {0.5, 1, 0.4} or {1, 0.5, 0.1}
    end
    Player.drawShip(p.x, p.y, 1, p.tilt, alpha, flame)

    if p.shield > 0 and util.blinkVisible(p.shield, 2) then
        local pulse = 0.35 + 0.15 * math.sin(time * 6)
        love.graphics.setColor(0.4, 0.85, 1, pulse * 0.5)
        love.graphics.circle("fill", p.x, p.y, p.radius + 10)
        love.graphics.setColor(0.6, 0.95, 1, pulse + 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", p.x, p.y, p.radius + 10)
        love.graphics.setLineWidth(1)
    end
end

return Player

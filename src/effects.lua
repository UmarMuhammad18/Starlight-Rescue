-- Visual effects: scrolling starfield, particles, floating text and screen shake

local config = require("src.config")
local util = require("src.util")
local fonts = require("src.fonts")

local effects = {}

local starfield = {}
local particleImage
local trail
local bursts = {}
local popups = {}
local shake = 0

function effects.load()
    -- Three parallax layers: far stars are small, dim and slow
    for layer = 1, 3 do
        for _ = 1, 50 - layer * 10 do
            table.insert(starfield, {
                x = love.math.random() * config.width,
                y = love.math.random() * config.height,
                speed = 12 * layer * layer,
                size = 0.6 + layer * 0.4,
                alpha = 0.2 + layer * 0.2,
            })
        end
    end

    -- Soft round dot used by every particle system
    local data = love.image.newImageData(16, 16)
    data:mapPixel(function(x, y)
        local a = math.max(0, 1 - util.distance(x + 0.5, y + 0.5, 8, 8) / 8)
        return 1, 1, 1, a * a
    end)
    particleImage = love.graphics.newImage(data)

    trail = love.graphics.newParticleSystem(particleImage, 200)
    trail:setParticleLifetime(0.2, 0.45)
    trail:setDirection(math.pi / 2)
    trail:setSpread(0.5)
    trail:setSpeed(80, 160)
    trail:setSizes(0.7, 0.1)
    trail:setEmissionRate(0)
end

function effects.clear()
    bursts = {}
    popups = {}
    shake = 0
    trail:setEmissionRate(0)
    trail:reset()
end

function effects.burst(x, y, color, count, speed)
    local ps = love.graphics.newParticleSystem(particleImage, count)
    ps:setParticleLifetime(0.3, 0.8)
    ps:setSpread(math.pi * 2)
    ps:setSpeed(speed * 0.3, speed)
    ps:setLinearDamping(2, 4)
    ps:setSizes(0.9, 0.1)
    ps:setColors(color[1], color[2], color[3], 1, color[1], color[2], color[3], 0)
    ps:setPosition(x, y)
    ps:emit(count)
    table.insert(bursts, ps)
end

function effects.popup(text, x, y, color, big)
    table.insert(popups, {
        text = text, x = x, y = y,
        color = color or {1, 1, 1},
        big = big,
        age = 0,
        life = big and 1.2 or 0.8,
    })
end

function effects.shake(amount)
    shake = math.max(shake, amount)
end

-- Engine exhaust behind the ship
function effects.setTrail(x, y, active, boosted)
    trail:setPosition(x, y + 12)
    trail:setEmissionRate(active and 60 or 0)
    if boosted then
        trail:setColors(0.5, 1, 0.4, 0.9, 0.2, 1, 0.6, 0)
    else
        trail:setColors(1, 0.7, 0.2, 0.8, 1, 0.3, 0.1, 0)
    end
end

function effects.updateBackground(dt, speedMultiplier)
    for _, s in ipairs(starfield) do
        s.y = s.y + s.speed * dt * speedMultiplier
        if s.y > config.height then
            s.y = s.y - config.height
            s.x = love.math.random() * config.width
        end
    end
end

function effects.update(dt)
    trail:update(dt)
    for i = #bursts, 1, -1 do
        bursts[i]:update(dt)
        if bursts[i]:getCount() == 0 then table.remove(bursts, i) end
    end
    for i = #popups, 1, -1 do
        local p = popups[i]
        p.age = p.age + dt
        p.y = p.y - 40 * dt
        if p.age >= p.life then table.remove(popups, i) end
    end
    shake = math.max(0, shake - dt)
end

function effects.getShakeOffset()
    if shake <= 0 then return 0, 0 end
    local m = 8 * math.min(1, shake / 0.3)
    return util.randomFloat(-m, m), util.randomFloat(-m, m)
end

function effects.drawBackground()
    for _, s in ipairs(starfield) do
        love.graphics.setColor(0.8, 0.85, 1, s.alpha)
        love.graphics.circle("fill", s.x, s.y, s.size)
    end
end

function effects.drawTrail()
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(trail)
    love.graphics.setBlendMode("alpha")
end

function effects.drawBursts()
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1)
    for _, ps in ipairs(bursts) do love.graphics.draw(ps) end
    love.graphics.setBlendMode("alpha")
end

function effects.drawPopups()
    for _, p in ipairs(popups) do
        local font = p.big and fonts.large or fonts.medium
        love.graphics.setFont(font)
        util.setColor(p.color, 1 - (p.age / p.life) ^ 2)
        love.graphics.print(p.text, p.x - font:getWidth(p.text) / 2, p.y - font:getHeight() / 2)
    end
end

return effects

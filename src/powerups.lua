-- Power-ups that appear now and then: shield, magnet and speed boost

local config = require("src.config")
local util = require("src.util")
local fonts = require("src.fonts")

local Powerups = {}

-- `name` matches the timer field it sets on the player
Powerups.kinds = {
    { name = "shield", label = "SHIELD", icon = "S", color = {0.4, 0.85, 1} },
    { name = "magnet", label = "MAGNET", icon = "M", color = {0.85, 0.5, 1} },
    { name = "boost",  label = "BOOST",  icon = "B", color = {0.6, 1, 0.3} },
}

function Powerups.new()
    return { list = {}, timer = config.powerups.firstSpawn }
end

function Powerups.durationFor(kind)
    return kind.name == "shield" and config.powerups.shieldDuration or config.powerups.duration
end

local function spawn(pu, player)
    local kind = Powerups.kinds[love.math.random(#Powerups.kinds)]
    -- Try for a spot that isn't right on top of the player
    local x, y
    for _ = 1, 10 do
        x = love.math.random(60, config.width - 60)
        y = love.math.random(120, config.height - 80)
        if util.distance(x, y, player.x, player.y) > 200 then break end
    end
    table.insert(pu.list, {
        kind = kind, x = x, y = y, radius = 16,
        life = config.powerups.lifetime,
        bob = love.math.random() * math.pi * 2,
    })
end

-- Returns the power-up the player picked up this frame, if any
function Powerups.update(pu, dt, player)
    pu.timer = pu.timer - dt
    if pu.timer <= 0 then
        spawn(pu, player)
        pu.timer = config.powerups.spawnEvery + util.randomFloat(-3, 3)
    end

    local picked
    for i = #pu.list, 1, -1 do
        local item = pu.list[i]
        item.life = item.life - dt
        item.bob = item.bob + dt * 3
        if util.overlaps(player, item) then
            picked = item
            table.remove(pu.list, i)
        elseif item.life <= 0 then
            table.remove(pu.list, i)
        end
    end
    return picked
end

-- Also used by the HUD and title screen
function Powerups.drawBadge(kind, x, y, size)
    util.setColor(kind.color, 0.2)
    love.graphics.circle("fill", x, y, size * 1.6)
    util.setColor(kind.color)
    love.graphics.rectangle("fill", x - size, y - size, size * 2, size * 2, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x - size, y - size, size * 2, size * 2, 6, 6)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.05, 0.05, 0.15)
    love.graphics.printf(kind.icon, x - size, y - fonts.small:getHeight() / 2, size * 2, "center")
end

function Powerups.draw(pu)
    for _, item in ipairs(pu.list) do
        if util.blinkVisible(item.life, 2) then
            Powerups.drawBadge(item.kind, item.x, item.y + math.sin(item.bob) * 4, 14)
        end
    end
end

return Powerups

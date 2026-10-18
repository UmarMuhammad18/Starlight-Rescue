-- Drones that chase the player. More (and faster) drones appear as the score rises.

local config = require("src.config")
local util = require("src.util")

local Enemies = {}

-- Drones always enter at whichever edge point is farthest from the player
local function farthestSpawnPoint(player)
    local w, h, m = config.width, config.height, 40
    local points = {
        {m, m}, {w / 2, m}, {w - m, m},
        {m, h / 2}, {w - m, h / 2},
        {m, h - m}, {w - m, h - m},
    }
    local best, bestDist = points[1], -1
    for _, point in ipairs(points) do
        local d = util.distance(point[1], point[2], player.x, player.y)
        if d > bestDist then best, bestDist = point, d end
    end
    return best[1], best[2]
end

local function newDrone(player)
    local x, y = farthestSpawnPoint(player)
    return { x = x, y = y, radius = config.enemy.radius, angle = 0, warp = config.enemy.warpTime }
end

function Enemies.new(player)
    return { drones = { newDrone(player) } }
end

function Enemies.speedFor(score)
    local c = config.enemy
    return math.min(c.maxSpeed, c.baseSpeed + score * c.speedPerPoint)
end

function Enemies.targetCount(score)
    local c = config.enemy
    return math.min(c.maxDrones, 1 + math.floor(score / c.extraDroneEvery))
end

-- Returns true when a new drone appeared this frame
function Enemies.update(e, dt, player, score)
    local spawned = false
    if #e.drones < Enemies.targetCount(score) then
        table.insert(e.drones, newDrone(player))
        spawned = true
    end

    local speed = Enemies.speedFor(score)
    for _, d in ipairs(e.drones) do
        d.angle = d.angle + dt * 1.5
        if d.warp > 0 then
            d.warp = d.warp - dt
        else
            local dx, dy = player.x - d.x, player.y - d.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                d.x = d.x + dx / dist * speed * dt
                d.y = d.y + dy / dist * speed * dt
            end
        end
    end

    -- Push overlapping drones apart so they don't merge into one
    for i = 1, #e.drones do
        for j = i + 1, #e.drones do
            local a, b = e.drones[i], e.drones[j]
            local dx, dy = b.x - a.x, b.y - a.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local minDist = a.radius + b.radius
            if dist > 0 and dist < minDist then
                local push = (minDist - dist) / 2
                local nx, ny = dx / dist, dy / dist
                a.x, a.y = a.x - nx * push, a.y - ny * push
                b.x, b.y = b.x + nx * push, b.y + ny * push
            end
        end
    end

    for _, d in ipairs(e.drones) do
        d.x = util.clamp(d.x, d.radius, config.width - d.radius)
        d.y = util.clamp(d.y, d.radius, config.height - d.radius)
    end

    return spawned
end

-- Returns the first active drone touching the player, if any
function Enemies.checkHit(e, player)
    for _, d in ipairs(e.drones) do
        if d.warp <= 0 and util.overlaps(d, player) then return d end
    end
end

function Enemies.warpAway(drone, player)
    drone.x, drone.y = farthestSpawnPoint(player)
    drone.warp = config.enemy.warpTime
end

function Enemies.draw(e, player)
    local size = config.enemy.size
    for _, d in ipairs(e.drones) do
        local alpha = 1
        if d.warp > 0 then
            -- Flicker in with a shrinking warning ring
            alpha = 0.25 + 0.35 * (math.floor(d.warp * 10) % 2)
            love.graphics.setColor(1, 0.3, 0.3, 0.6)
            love.graphics.circle("line", d.x, d.y, d.radius + 30 * d.warp / config.enemy.warpTime)
        end

        love.graphics.push()
        love.graphics.translate(d.x, d.y)

        love.graphics.setColor(1, 0.2, 0.2, 0.15 * alpha)
        love.graphics.circle("fill", 0, 0, d.radius * 1.8)

        love.graphics.push()
        love.graphics.rotate(d.angle)
        love.graphics.setColor(1, 0.2, 0.2, alpha)
        love.graphics.rectangle("fill", -size / 2, -size / 2, size, size, 5, 5)
        love.graphics.setColor(1, 0.5, 0.5, alpha)
        love.graphics.rectangle("line", -size / 2, -size / 2, size, size, 5, 5)
        love.graphics.pop()

        -- Eye that tracks the player
        local dx, dy = player.x - d.x, player.y - d.y
        local dist = math.max(1, math.sqrt(dx * dx + dy * dy))
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", dx / dist * 6, dy / dist * 6, 5)
        love.graphics.setColor(0.2, 0, 0, alpha)
        love.graphics.circle("fill", dx / dist * 8, dy / dist * 8, 2.5)

        love.graphics.pop()
    end
end

return Enemies

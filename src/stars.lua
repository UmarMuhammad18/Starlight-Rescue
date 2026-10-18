-- Falling collectibles: regular, gold, extra-life and hazardous "bad" stars

local config = require("src.config")
local util = require("src.util")

local Stars = {}

Stars.kinds = {
    { name = "normal", points = 10, radius = 10, color = {0.2, 0.8, 1},   weight = 80 },
    { name = "gold",   points = 50, radius = 13, color = {1, 0.85, 0.2},  weight = 7, speedMultiplier = 1.35 },
    { name = "life",   life = true, radius = 12, color = {0.35, 1, 0.45}, weight = 3 },
    { name = "bad",    bad = true,  radius = 12, color = {1, 0.25, 0.3},  weight = 14, minScore = 50 },
}
for _, kind in ipairs(Stars.kinds) do Stars.kinds[kind.name] = kind end

function Stars.new()
    return { list = {}, timer = 0, delay = config.stars.startDelay }
end

local function pickKind(score, lives)
    local options = {}
    for _, kind in ipairs(Stars.kinds) do
        local allowed = (not kind.minScore or score >= kind.minScore)
            and (not kind.life or lives < config.maxLives)
        if allowed then table.insert(options, kind) end
    end
    return util.weightedChoice(options)
end

local function spawn(s, score, lives)
    local c = config.stars
    local kind = pickKind(score, lives)
    local speedMultiplier = math.min(c.maxSpeedMultiplier, 1 + score * c.speedPerPoint)
        * (kind.speedMultiplier or 1)
    table.insert(s.list, {
        kind = kind,
        x = love.math.random(20, config.width - 20),
        y = -20,
        radius = kind.radius,
        speed = love.math.random(c.minSpeed, c.maxSpeed) * speedMultiplier,
        rotation = love.math.random() * math.pi * 2,
        spin = util.randomFloat(-2, 2),
    })
end

-- Moves the stars and returns the ones the player touched this frame
function Stars.update(s, dt, player, score, lives)
    local c = config.stars
    s.timer = s.timer + dt
    if s.timer >= s.delay then
        s.timer = 0
        spawn(s, score, lives)
    end

    local touched = {}
    -- Iterate backwards so removing a star never skips the next one
    for i = #s.list, 1, -1 do
        local star = s.list[i]
        star.y = star.y + star.speed * dt
        star.rotation = star.rotation + star.spin * dt

        if player.magnet > 0 and not star.kind.bad then
            local dx, dy = player.x - star.x, player.y - star.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 and dist < config.powerups.magnetRange then
                local pull = math.min(dist, config.powerups.magnetPull * dt)
                star.x = star.x + dx / dist * pull
                star.y = star.y + dy / dist * pull
            end
        end

        -- Bad stars pass harmlessly through a blinking (invulnerable) ship
        local canTouch = not star.kind.bad or player.invuln <= 0
        if canTouch and util.overlaps(player, star) then
            table.remove(s.list, i)
            table.insert(touched, star)
            if not star.kind.bad then
                s.delay = math.max(c.minDelay, s.delay - c.delayStep)
            end
        elseif star.y > config.height + star.radius then
            table.remove(s.list, i)
        end
    end
    return touched
end

local function starPoints(x, y, outer, inner, points, rotation)
    local outerPts, innerPts = {}, {}
    for k = 0, points - 1 do
        local a = rotation + k * math.pi * 2 / points - math.pi / 2
        local b = a + math.pi / points
        outerPts[k + 1] = { x + math.cos(a) * outer, y + math.sin(a) * outer }
        innerPts[k + 1] = { x + math.cos(b) * inner, y + math.sin(b) * inner }
    end
    return outerPts, innerPts
end

-- Star shapes are concave, so fill them as a convex center plus one triangle per spike
local function fillStar(x, y, outer, inner, points, rotation)
    local outerPts, innerPts = starPoints(x, y, outer, inner, points, rotation)
    local center = {}
    for k = 1, points do
        local prev = innerPts[(k - 2) % points + 1]
        love.graphics.polygon("fill", prev[1], prev[2],
            outerPts[k][1], outerPts[k][2], innerPts[k][1], innerPts[k][2])
        table.insert(center, innerPts[k][1])
        table.insert(center, innerPts[k][2])
    end
    love.graphics.polygon("fill", center)
end

local function outlineStar(x, y, outer, inner, points, rotation)
    local outerPts, innerPts = starPoints(x, y, outer, inner, points, rotation)
    local vertices = {}
    for k = 1, points do
        table.insert(vertices, outerPts[k][1])
        table.insert(vertices, outerPts[k][2])
        table.insert(vertices, innerPts[k][1])
        table.insert(vertices, innerPts[k][2])
    end
    love.graphics.polygon("line", vertices)
end

-- Also used by the title screen legend
function Stars.drawKind(kind, x, y, radius, rotation, time)
    local color = kind.color
    local pulse = 1 + 0.12 * math.sin(time * 8 + x)

    util.setColor(color, 0.18)
    love.graphics.circle("fill", x, y, radius * 1.9 * pulse)

    if kind.bad then
        util.setColor(color)
        fillStar(x, y, radius * 1.15 * pulse, radius * 0.55, 8, rotation)
        love.graphics.setColor(0.3, 0, 0)
        love.graphics.circle("fill", x, y, radius * 0.35)
        return
    end

    util.setColor(color)
    fillStar(x, y, radius * 1.2, radius * 0.55, 5, rotation)
    love.graphics.setColor(1, 1, 1, 0.9)
    outlineStar(x, y, radius * 1.2, radius * 0.55, 5, rotation)

    if kind.life then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x - 1.5, y - 5, 3, 10)
        love.graphics.rectangle("fill", x - 5, y - 1.5, 10, 3)
    end
end

function Stars.draw(s, time)
    for _, star in ipairs(s.list) do
        Stars.drawKind(star.kind, star.x, star.y, star.radius, star.rotation, time)
    end
end

return Stars

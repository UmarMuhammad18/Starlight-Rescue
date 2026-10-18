local util = {}

function util.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function util.lerp(a, b, t)
    return a + (b - a) * t
end

function util.distance(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

-- True when two circles ({x, y, radius}) touch
function util.overlaps(a, b)
    return util.distance(a.x, a.y, b.x, b.y) < a.radius + b.radius
end

function util.randomFloat(lo, hi)
    return lo + love.math.random() * (hi - lo)
end

-- Picks an entry from a list of tables that each have a `weight` field
function util.weightedChoice(options)
    local total = 0
    for _, option in ipairs(options) do total = total + option.weight end
    local roll = love.math.random() * total
    for _, option in ipairs(options) do
        roll = roll - option.weight
        if roll <= 0 then return option end
    end
    return options[#options]
end

-- Visible normally, blinking once fewer than `warnAt` seconds remain
function util.blinkVisible(timeLeft, warnAt)
    return timeLeft > warnAt or math.floor(timeLeft * 8) % 2 == 0
end

function util.setColor(color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * (alpha or 1))
end

return util

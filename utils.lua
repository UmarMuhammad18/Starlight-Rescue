local Utils = {}

function Utils.clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Utils.normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len == 0 then return 0, 0 end
    return x / len, y / len
end

function Utils.circleCollision(x1, y1, r1, x2, y2, r2)
    return Utils.dist(x1, y1, x2, y2) < (r1 + r2)
end

function Utils.randomChoice(t)
    return t[love.math.random(#t)]
end

function Utils.drawGlowCircle(x, y, r, color, glowColor, glowExtra)
    glowExtra = glowExtra or 4
    love.graphics.setColor(glowColor)
    love.graphics.circle("fill", x, y, r + glowExtra)
    love.graphics.setColor(color)
    love.graphics.circle("fill", x, y, r)
end

return Utils

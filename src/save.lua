-- High score persistence (stored in LÖVE's save folder, see conf.lua identity)

local save = {}

local FILE = "highscore.txt"

function save.loadHighScore()
    if not love.filesystem.getInfo(FILE) then return 0 end
    local contents = love.filesystem.read(FILE)
    return tonumber(contents) or 0
end

function save.saveHighScore(score)
    love.filesystem.write(FILE, tostring(score))
end

return save

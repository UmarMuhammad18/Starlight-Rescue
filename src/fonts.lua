local fonts = {}

function fonts.load()
    fonts.small = love.graphics.newFont(16)
    fonts.medium = love.graphics.newFont(22)
    fonts.large = love.graphics.newFont(30)
    fonts.huge = love.graphics.newFont(56)
end

return fonts

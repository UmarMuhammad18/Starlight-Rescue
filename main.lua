--[[
    Starlight Rescue
    A polished "collect the stars" arcade game built with Love2D.

    Controls:
      WASD / Arrow Keys  - Move
      Gamepad            - Left stick
      P / Esc            - Pause
      R / Space          - Restart (when game over)
      Space / Enter      - Start from title
]]

local Game = require("game")

local game

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    love.math.setRandomSeed(os.time())
    game = Game.new()
end

function love.update(dt)
    -- prevent huge dt spikes
    dt = math.min(dt, 1 / 20)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.keypressed(key)
    game:keypressed(key)
end

-- Optional: restart with focus loss handling can be added later

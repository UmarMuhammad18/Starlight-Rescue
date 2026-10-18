-- HUD and full-screen menus

local config = require("src.config")
local util = require("src.util")
local fonts = require("src.fonts")
local audio = require("src.audio")
local Player = require("src.player")
local Stars = require("src.stars")
local Powerups = require("src.powerups")

local ui = {}

local WHITE = {1, 1, 1}
local GRAY = {0.65, 0.7, 0.85}
local GOLD = {1, 0.85, 0.3}

local scoreScale = 1
local displayScore = 0

function ui.reset()
    scoreScale = 1
    displayScore = 0
end

function ui.bumpScore()
    scoreScale = 1.35
end

function ui.update(dt, game)
    scoreScale = util.lerp(scoreScale, 1, math.min(1, dt * 8))
    -- Count up toward the real score
    displayScore = util.lerp(displayScore, game.score, math.min(1, dt * 12))
    if math.abs(displayScore - game.score) < 0.5 then displayScore = game.score end
end

local function printCentered(text, font, y, color)
    love.graphics.setFont(font)
    util.setColor(color or WHITE)
    love.graphics.printf(text, 0, y, config.width, "center")
end

local function drawOverlay(alpha)
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, config.width, config.height)
end

function ui.drawHUD(game)
    -- Score, scaled up briefly whenever it changes
    local font = fonts.large
    local h = font:getHeight()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. math.floor(displayScore + 0.5), 20, 18 + h / 2, 0,
        scoreScale, scoreScale, 0, h / 2)

    for i = 1, game.lives do
        Player.drawShip(30 + (i - 1) * 28, 80, 0.55, 0, 1)
    end

    local combo = game.combo
    if combo.multiplier > 1 then
        love.graphics.setFont(fonts.medium)
        love.graphics.setColor(1, 0.6, 0.2)
        love.graphics.print("COMBO x" .. combo.multiplier, 20, 102)
        love.graphics.setColor(1, 0.6, 0.2, 0.3)
        love.graphics.rectangle("fill", 20, 130, 120, 5)
        love.graphics.setColor(1, 0.6, 0.2)
        love.graphics.rectangle("fill", 20, 130, 120 * combo.timer / config.combo.window, 5)
    end

    love.graphics.setFont(fonts.medium)
    util.setColor(GRAY)
    love.graphics.printf("Best: " .. math.max(game.highScore, game.score), 0, 24, config.width - 20, "right")

    -- Active power-ups with their remaining time
    local y = 70
    for _, kind in ipairs(Powerups.kinds) do
        local timeLeft = game.player[kind.name]
        if timeLeft > 0 then
            local x = config.width - 130
            Powerups.drawBadge(kind, x, y, 10)
            util.setColor(kind.color, 0.3)
            love.graphics.rectangle("fill", x + 18, y - 3, 90, 6)
            util.setColor(kind.color)
            love.graphics.rectangle("fill", x + 18, y - 3, 90 * timeLeft / Powerups.durationFor(kind), 6)
            y = y + 30
        end
    end
end

function ui.drawMenu(game)
    local time = game.clock
    printCentered("STARLIGHT RESCUE", fonts.huge, 90 + math.sin(time * 2) * 6, GOLD)
    printCentered("Collect the falling stars. Dodge the drones.", fonts.medium, 170, GRAY)

    local legend = {
        { Stars.kinds.normal, "10 pts" },
        { Stars.kinds.gold, "50 pts" },
        { Stars.kinds.life, "+1 life" },
        { Stars.kinds.bad, "Avoid!" },
    }
    love.graphics.setFont(fonts.small)
    for i, entry in ipairs(legend) do
        local cx = 100 + (i - 0.5) * 150
        Stars.drawKind(entry[1], cx, 240, entry[1].radius, time, time)
        util.setColor(WHITE)
        love.graphics.printf(entry[2], cx - 75, 268, 150, "center")
    end

    local powerupInfo = { "Blocks one hit", "Pulls stars in", "Faster ship" }
    for i, kind in ipairs(Powerups.kinds) do
        local cx = 100 + (i - 0.5) * 200
        Powerups.drawBadge(kind, cx, 330, 14)
        love.graphics.setFont(fonts.small)
        util.setColor(kind.color)
        love.graphics.printf(kind.label, cx - 100, 356, 200, "center")
        util.setColor(GRAY)
        love.graphics.printf(powerupInfo[i], cx - 100, 376, 200, "center")
    end

    printCentered("Best: " .. game.highScore, fonts.large, 420, WHITE)
    if math.floor(time * 2) % 2 == 0 then
        printCentered("Press Enter or Space to start", fonts.medium, 475, GOLD)
    end
    printCentered("Move: Arrows / WASD / Gamepad     Pause: P / Esc     Mute: M     Quit: Esc",
        fonts.small, 550, GRAY)
end

function ui.drawPause()
    drawOverlay(0.6)
    printCentered("PAUSED", fonts.huge, 200)
    printCentered("P / Esc / Enter to resume", fonts.medium, 290, GRAY)
    printCentered("R to restart     Q for menu     M to mute", fonts.medium, 325, GRAY)
end

function ui.drawGameOver(game)
    drawOverlay(0.75)
    printCentered("GAME OVER", fonts.huge, 160, {1, 0.4, 0.4})
    printCentered("Final Score: " .. game.score, fonts.large, 250)
    if game.newHighScore then
        if math.floor(game.clock * 4) % 2 == 0 then
            printCentered("NEW HIGH SCORE!", fonts.large, 300, GOLD)
        end
    else
        printCentered("Best: " .. game.highScore, fonts.medium, 305, GRAY)
    end
    printCentered("Press R or Enter to play again", fonts.medium, 380)
    printCentered("Esc for menu", fonts.small, 420, GRAY)
end

function ui.drawMuted()
    if audio.isMuted() then
        love.graphics.setFont(fonts.small)
        util.setColor(GRAY)
        love.graphics.printf("MUTED", 0, config.height - 28, config.width - 16, "right")
    end
end

return ui

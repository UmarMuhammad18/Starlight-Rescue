-- Starlight Rescue: A "Collect the Stars" Game

local config   = require("src.config")
local fonts    = require("src.fonts")
local input    = require("src.input")
local audio    = require("src.audio")
local save     = require("src.save")
local effects  = require("src.effects")
local Player   = require("src.player")
local Enemies  = require("src.enemies")
local Stars    = require("src.stars")
local Powerups = require("src.powerups")
local ui       = require("src.ui")

local game = {
    state = "menu",  -- "menu", "playing", "paused" or "gameover"
    clock = 0,       -- always ticking; drives animations
}

local function resetGame()
    game.score = 0
    game.lives = config.startLives
    game.combo = { streak = 0, timer = 0, multiplier = 1 }
    game.newHighScore = false
    game.player = Player.new()
    game.enemies = Enemies.new(game.player)
    game.stars = Stars.new()
    game.powerups = Powerups.new()
    effects.clear()
    ui.reset()
end

local function startGame()
    resetGame()
    game.state = "playing"
    audio.setMusicQuiet(false)
    audio.play("start")
end

local function gameOver()
    game.state = "gameover"
    if game.score > game.highScore then
        game.highScore = game.score
        game.newHighScore = true
        save.saveHighScore(game.score)
    end
    local p = game.player
    effects.setTrail(p.x, p.y, false, false)
    effects.burst(p.x, p.y, {1, 0.8, 0.2}, 80, 320)
    effects.shake(0.5)
    audio.play("gameover")
    audio.setMusicQuiet(true)
end

local function addScore(points)
    game.score = game.score + points
    ui.bumpScore()
end

local function breakCombo()
    game.combo.streak = 0
    game.combo.timer = 0
    game.combo.multiplier = 1
end

-- A shield absorbs the hit; otherwise lose a life
local function hurtPlayer()
    local p = game.player
    if p.shield > 0 then
        p.shield = 0
        p.invuln = 0.6
        effects.burst(p.x, p.y, {0.4, 0.85, 1}, 40, 260)
        effects.popup("SHIELD!", p.x, p.y - 40, {0.4, 0.85, 1})
        effects.shake(0.15)
        audio.play("shield")
        return
    end

    game.lives = game.lives - 1
    p.invuln = config.invulnTime
    breakCombo()
    effects.burst(p.x, p.y, {1, 0.3, 0.3}, 40, 260)
    effects.shake(0.3)
    audio.play("hit")
    if game.lives <= 0 then gameOver() end
end

local function collectStar(star)
    local kind = star.kind
    if kind.bad then
        effects.burst(star.x, star.y, kind.color, 25, 200)
        hurtPlayer()
        return
    end

    local combo = game.combo
    combo.streak = combo.streak + 1
    combo.timer = config.combo.window
    local multiplier = math.min(config.combo.maxMultiplier,
        1 + math.floor(combo.streak / config.combo.starsPerLevel))
    if multiplier > combo.multiplier then
        effects.popup("COMBO x" .. multiplier, config.width / 2, 140, {1, 0.6, 0.2}, true)
        audio.play("combo")
    end
    combo.multiplier = multiplier

    effects.burst(star.x, star.y, kind.color, 18, 180)

    if kind.life and game.lives < config.maxLives then
        game.lives = game.lives + 1
        effects.popup("+1 LIFE", star.x, star.y, kind.color)
        audio.play("life")
    else
        -- A life star at full lives is worth a small bonus instead
        local points = (kind.points or 25) * multiplier
        addScore(points)
        effects.popup("+" .. points, star.x, star.y, kind.color)
        audio.play(kind.name == "gold" and "gold" or "collect")
    end
end

local function applyPowerup(item)
    local kind = item.kind
    game.player[kind.name] = Powerups.durationFor(kind)
    effects.burst(item.x, item.y, kind.color, 30, 220)
    effects.popup(kind.label, item.x, item.y - 20, kind.color, true)
    audio.play("powerup")
end

local function updatePlaying(dt)
    local p = game.player
    local moveX, moveY = input.getMovement()
    Player.update(p, dt, moveX, moveY)
    effects.setTrail(p.x, p.y, p.moving, p.boost > 0)

    if Enemies.update(game.enemies, dt, p, game.score) then
        effects.popup("DRONE INCOMING!", config.width / 2, 180, {1, 0.3, 0.3}, true)
        audio.play("drone")
    end

    if p.invuln <= 0 then
        local drone = Enemies.checkHit(game.enemies, p)
        if drone then
            hurtPlayer()
            Enemies.warpAway(drone, p)
            if game.state ~= "playing" then return end
        end
    end

    for _, star in ipairs(Stars.update(game.stars, dt, p, game.score, game.lives)) do
        collectStar(star)
        if game.state ~= "playing" then return end
    end

    local item = Powerups.update(game.powerups, dt, p)
    if item then applyPowerup(item) end

    local combo = game.combo
    if combo.timer > 0 then
        combo.timer = combo.timer - dt
        if combo.timer <= 0 then breakCombo() end
    end
end

local function setPaused(paused)
    game.state = paused and "paused" or "playing"
    audio.setMusicQuiet(paused)
    audio.play("pause")
end

local function goToMenu()
    game.state = "menu"
    audio.setMusicQuiet(false)
end

local function handleAction(action)
    if action == "mute" then
        audio.toggleMute()
        return
    end

    local state = game.state
    if state == "menu" then
        if action == "confirm" or action == "pause" then startGame()
        elseif action == "escape" or action == "back" then love.event.quit() end
    elseif state == "playing" then
        if action == "pause" or action == "escape" then setPaused(true) end
    elseif state == "paused" then
        if action == "pause" or action == "escape" or action == "confirm" then setPaused(false)
        elseif action == "restart" then startGame()
        elseif action == "back" then goToMenu() end
    elseif state == "gameover" then
        if action == "confirm" or action == "restart" or action == "pause" then startGame()
        elseif action == "escape" or action == "back" then goToMenu() end
    end
end

function love.load()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.15)
    fonts.load()
    effects.load()
    audio.load()
    game.highScore = save.loadHighScore()
    resetGame()
    audio.playMusic()
end

function love.update(dt)
    -- Avoid huge jumps after the window is dragged or the game hitches
    dt = math.min(dt, 1 / 30)
    game.clock = game.clock + dt
    if game.state == "paused" then return end

    local boosting = game.state == "playing" and game.player.boost > 0
    effects.updateBackground(dt, boosting and 2 or 1)
    if game.state == "playing" then updatePlaying(dt) end
    effects.update(dt)
    ui.update(dt, game)
end

local function drawWorld()
    Powerups.draw(game.powerups)
    Stars.draw(game.stars, game.clock)
    effects.drawTrail()
    Enemies.draw(game.enemies, game.player)
    if game.state ~= "gameover" then Player.draw(game.player, game.clock) end
    effects.drawBursts()
    effects.drawPopups()
end

function love.draw()
    effects.drawBackground()

    if game.state == "menu" then
        ui.drawMenu(game)
    else
        local shakeX, shakeY = 0, 0
        if game.state ~= "paused" then shakeX, shakeY = effects.getShakeOffset() end
        love.graphics.push()
        love.graphics.translate(shakeX, shakeY)
        drawWorld()
        love.graphics.pop()

        ui.drawHUD(game)
        if game.state == "paused" then ui.drawPause()
        elseif game.state == "gameover" then ui.drawGameOver(game) end
    end

    ui.drawMuted()
end

function love.keypressed(key)
    local action = input.actionForKey(key)
    if action then handleAction(action) end
end

function love.gamepadpressed(_, button)
    local action = input.actionForButton(button)
    if action then handleAction(action) end
end

-- Pause automatically when the window loses focus
function love.focus(focused)
    if not focused and game.state == "playing" then setPaused(true) end
end

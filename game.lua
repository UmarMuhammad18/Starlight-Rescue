local Config = require("config")
local Utils = require("utils")
local Player = require("player")
local Enemy = require("enemy")
local Star = require("star")
local Particles = require("particles")
local Background = require("background")

local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.state = "title" -- title | playing | paused | gameover
    self.highScore = 0
    self:loadHighScore()
    self.bg = Background.new()
    self.particles = Particles.new()
    self.fonts = {
        big   = love.graphics.newFont(42),
        med   = love.graphics.newFont(28),
        small = love.graphics.newFont(18),
        tiny  = love.graphics.newFont(14),
    }
    self.shake = 0
    self.message = nil
    self.messageTimer = 0
    self:reset()
    return self
end

function Game:loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        local data = love.filesystem.read("highscore.txt")
        self.highScore = tonumber(data) or 0
    end
end

function Game:saveHighScore()
    if self.score > self.highScore then
        self.highScore = self.score
        love.filesystem.write("highscore.txt", tostring(self.highScore))
    end
end

function Game:reset()
    self.player = Player.new()
    self.enemies = { Enemy.new(80, 60) }
    self.stars = {}
    self.particles:clear()
    self.score = 0
    self.lives = 3
    self.combo = 0
    self.comboTimer = 0
    self.spawnTimer = 0
    self.spawnDelay = Config.STAR_BASE_SPAWN
    self.difficulty = 1
    self.shake = 0
    self.message = nil
    self.messageTimer = 0
    self.scorePopups = {}
end

function Game:start()
    self:reset()
    self.state = "playing"
end

function Game:addScore(base)
    local points = base * self.player.mult * math.max(1, self.combo)
    self.score = self.score + points

    -- popup
    table.insert(self.scorePopups, {
        x = self.player.x,
        y = self.player.y - 30,
        text = "+" .. points,
        life = 0.8,
        maxLife = 0.8,
    })

    -- difficulty & extra enemies
    local newDiff = 1 + math.floor(self.score / Config.DIFFICULTY_SCORE_STEP)
    if newDiff > self.difficulty then
        self.difficulty = newDiff
        self:showMessage("Difficulty Up!")
        -- speed up existing enemies a bit
        for _, e in ipairs(self.enemies) do
            e.speed = Config.ENEMY_BASE_SPEED + (self.difficulty - 1) * Config.ENEMY_SPEED_SCALE
        end
    end

    local desiredEnemies = 1 + math.floor(self.score / Config.ENEMY_SPAWN_SCORE)
    desiredEnemies = math.min(desiredEnemies, Config.MAX_ENEMIES)
    while #self.enemies < desiredEnemies do
        local side = love.math.random(1, 4)
        local x, y
        if side == 1 then x, y = love.math.random(50, 750), 40
        elseif side == 2 then x, y = love.math.random(50, 750), 560
        elseif side == 3 then x, y = 40, love.math.random(50, 550)
        else x, y = 760, love.math.random(50, 550) end
        local e = Enemy.new(x, y)
        e.speed = Config.ENEMY_BASE_SPEED + (self.difficulty - 1) * Config.ENEMY_SPEED_SCALE
        table.insert(self.enemies, e)
        self:showMessage("Enemy Incoming!")
    end

    -- faster spawns
    self.spawnDelay = math.max(Config.STAR_MIN_SPAWN,
        Config.STAR_BASE_SPAWN - self.score * 0.00035)
end

function Game:showMessage(text)
    self.message = text
    self.messageTimer = 1.6
end

function Game:applyPowerup(ptype)
    if ptype == "shield" then
        self.player.shield = Config.POWERUP_DURATION
        self:showMessage("Shield!")
    elseif ptype == "slow" then
        self.player.slow = Config.POWERUP_DURATION
        self:showMessage("Time Slow!")
    elseif ptype == "magnet" then
        self.player.magnet = Config.POWERUP_DURATION
        self:showMessage("Magnet!")
    elseif ptype == "mult" then
        self.player.mult = 2
        self.player.multTimer = Config.POWERUP_DURATION
        self:showMessage("2x Score!")
    elseif ptype == "life" then
        self.lives = math.min(self.lives + 1, 5)
        self:showMessage("Extra Life!")
    end
    self.particles:spawn(self.player.x, self.player.y, {
        count = 18, speed = 160, life = 0.7,
        color = {0.4, 1, 0.8, 1}, size = 4
    })
end

function Game:update(dt)
    if self.state == "title" or self.state == "gameover" then
        self.bg:update(dt, 1)
        return
    end

    if self.state == "paused" then return end

    -- playing
    self.bg:update(dt, self.difficulty)
    self.player:update(dt)
    self.particles:update(dt)

    local slowFactor = self.player.slow > 0 and 0.45 or 1

    -- enemies
    for _, e in ipairs(self.enemies) do
        e:update(dt, self.player, slowFactor)
        if Utils.circleCollision(self.player.x, self.player.y, self.player.radius,
                                 e.x, e.y, e.radius) then
            if self.player:takeHit() then
                self.lives = self.lives - 1
                self.shake = 0.45
                self.combo = 0
                self.particles:spawn(self.player.x, self.player.y, {
                    count = 22, speed = 200, life = 0.7,
                    color = {1, 0.3, 0.2, 1}, size = 4, gravity = 40
                })
                if self.lives <= 0 then
                    self.state = "gameover"
                    self:saveHighScore()
                else
                    -- soft reset positions
                    self.player.x = Config.WINDOW_W / 2
                    self.player.y = Config.WINDOW_H - 70
                    for i, en in ipairs(self.enemies) do
                        en.x = 60 + (i - 1) * 40
                        en.y = 50 + (i - 1) * 30
                    end
                end
            else
                -- shield absorbed or invuln
                if self.player.shield <= 0 then
                    -- just invuln, small feedback
                    self.shake = 0.12
                end
            end
        end
    end

    -- spawn stars
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnDelay then
        self.spawnTimer = 0
        local isPower = love.math.random() < Config.POWERUP_CHANCE
        table.insert(self.stars, Star.new(isPower))
    end

    -- update stars
    for i = #self.stars, 1, -1 do
        local s = self.stars[i]
        s:update(dt, self.player)

        if Utils.circleCollision(self.player.x, self.player.y, self.player.radius,
                                 s.x, s.y, s.radius) then
            if s.isPowerup then
                self:applyPowerup(s.powerType)
            else
                self.combo = math.min(self.combo + 1, Config.COMBO_MAX)
                self.comboTimer = Config.COMBO_WINDOW
                self:addScore(Config.STAR_POINTS)
                self.particles:spawn(s.x, s.y, {
                    count = 12, speed = 110, life = 0.5,
                    color = {0.3, 0.9, 1, 1}, size = 3
                })
            end
            table.remove(self.stars, i)
        elseif s.y > Config.WINDOW_H + 30 then
            table.remove(self.stars, i)
            -- missed star softens combo
            self.comboTimer = self.comboTimer - 0.4
        end
    end

    -- combo decay
    if self.combo > 0 then
        self.comboTimer = self.comboTimer - dt
        if self.comboTimer <= 0 then
            self.combo = 0
        end
    end

    -- score popups
    for i = #self.scorePopups, 1, -1 do
        local p = self.scorePopups[i]
        p.y = p.y - 40 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(self.scorePopups, i) end
    end

    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then self.message = nil end
    end

    if self.shake > 0 then
        self.shake = self.shake - dt * Config.SHAKE_DECAY
    end
end

function Game:draw()
    local sx, sy = 0, 0
    if self.shake > 0 then
        sx = love.math.random(-6, 6) * self.shake
        sy = love.math.random(-6, 6) * self.shake
    end
    love.graphics.push()
    love.graphics.translate(sx, sy)

    self.bg:draw()

    if self.state == "playing" or self.state == "paused" then
        for _, s in ipairs(self.stars) do s:draw() end
        for _, e in ipairs(self.enemies) do e:draw() end
        self.player:draw()
        self.particles:draw()

        -- score popups
        love.graphics.setFont(self.fonts.small)
        for _, p in ipairs(self.scorePopups) do
            local a = p.life / p.maxLife
            love.graphics.setColor(1, 1, 0.6, a)
            love.graphics.printf(p.text, p.x - 40, p.y, 80, "center")
        end

        self:drawHUD()
    end

    love.graphics.pop()

    if self.state == "title" then
        self:drawTitle()
    elseif self.state == "paused" then
        self:drawPause()
    elseif self.state == "gameover" then
        self:drawGameOver()
    end
end

function Game:drawHUD()
    love.graphics.setFont(self.fonts.med)
    love.graphics.setColor(Config.COLOR.text)
    love.graphics.print("Score  " .. self.score, 18, 14)

    if self.combo > 1 then
        love.graphics.setColor(Config.COLOR.accent)
        love.graphics.print("x" .. self.combo .. " Combo", 18, 48)
    end

    -- lives as hearts
    love.graphics.setFont(self.fonts.small)
    for i = 1, self.lives do
        love.graphics.setColor(1, 0.35, 0.4)
        love.graphics.print("♥", Config.WINDOW_W - 30 - (i - 1) * 26, 16)
    end

    -- active power indicators
    local y = 80
    love.graphics.setFont(self.fonts.tiny)
    if self.player.shield > 0 then
        love.graphics.setColor(0.3, 0.9, 1)
        love.graphics.print(string.format("Shield %.1fs", self.player.shield), 18, y)
        y = y + 18
    end
    if self.player.slow > 0 then
        love.graphics.setColor(0.7, 0.5, 1)
        love.graphics.print(string.format("Slow %.1fs", self.player.slow), 18, y)
        y = y + 18
    end
    if self.player.magnet > 0 then
        love.graphics.setColor(1, 0.6, 0.3)
        love.graphics.print(string.format("Magnet %.1fs", self.player.magnet), 18, y)
        y = y + 18
    end
    if self.player.mult > 1 then
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.print(string.format("2x %.1fs", self.player.multTimer), 18, y)
    end

    if self.message then
        love.graphics.setFont(self.fonts.med)
        love.graphics.setColor(1, 1, 1, math.min(1, self.messageTimer))
        love.graphics.printf(self.message, 0, Config.WINDOW_H / 2 - 80, Config.WINDOW_W, "center")
    end
end

function Game:drawTitle()
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_W, Config.WINDOW_H)

    love.graphics.setFont(self.fonts.big)
    love.graphics.setColor(Config.COLOR.accent)
    love.graphics.printf("STARLIGHT RESCUE", 0, 160, Config.WINDOW_W, "center")

    love.graphics.setFont(self.fonts.med)
    love.graphics.setColor(Config.COLOR.dim)
    love.graphics.printf("Collect the stars. Survive the drones.", 0, 230, Config.WINDOW_W, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(Config.COLOR.text)
    love.graphics.printf("WASD / Arrows  ·  Gamepad supported", 0, 320, Config.WINDOW_W, "center")
    love.graphics.printf("P or Esc to Pause", 0, 348, Config.WINDOW_W, "center")

    love.graphics.setColor(Config.COLOR.accent)
    love.graphics.printf("Press SPACE or ENTER to Start", 0, 420, Config.WINDOW_W, "center")

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(Config.COLOR.dim)
    love.graphics.printf("High Score: " .. self.highScore, 0, 520, Config.WINDOW_W, "center")
end

function Game:drawPause()
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_W, Config.WINDOW_H)
    love.graphics.setFont(self.fonts.big)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 240, Config.WINDOW_W, "center")
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(Config.COLOR.dim)
    love.graphics.printf("P / Esc to Resume   ·   R to Restart", 0, 310, Config.WINDOW_W, "center")
end

function Game:drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, Config.WINDOW_W, Config.WINDOW_H)

    love.graphics.setFont(self.fonts.big)
    love.graphics.setColor(Config.COLOR.danger)
    love.graphics.printf("GAME OVER", 0, 180, Config.WINDOW_W, "center")

    love.graphics.setFont(self.fonts.med)
    love.graphics.setColor(Config.COLOR.text)
    love.graphics.printf("Score: " .. self.score, 0, 260, Config.WINDOW_W, "center")

    if self.score >= self.highScore and self.score > 0 then
        love.graphics.setColor(Config.COLOR.accent)
        love.graphics.printf("NEW HIGH SCORE!", 0, 300, Config.WINDOW_W, "center")
    else
        love.graphics.setColor(Config.COLOR.dim)
        love.graphics.printf("High Score: " .. self.highScore, 0, 300, Config.WINDOW_W, "center")
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(Config.COLOR.text)
    love.graphics.printf("Press R or SPACE to Restart", 0, 400, Config.WINDOW_W, "center")
    love.graphics.printf("Esc for Title Screen", 0, 430, Config.WINDOW_W, "center")
end

function Game:keypressed(key)
    if self.state == "title" then
        if key == "space" or key == "return" then
            self:start()
        end
    elseif self.state == "playing" then
        if key == "p" or key == "escape" then
            self.state = "paused"
        end
    elseif self.state == "paused" then
        if key == "p" or key == "escape" then
            self.state = "playing"
        elseif key == "r" then
            self:start()
        end
    elseif self.state == "gameover" then
        if key == "r" or key == "space" or key == "return" then
            self:start()
        elseif key == "escape" then
            self.state = "title"
            self:reset()
        end
    end
end

return Game

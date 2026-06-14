-- Starlight Rescue: A "Collect the Stars" Game

function love.load()
    -- Set up the game window
    love.window.setTitle("Starlight Rescue")
    love.window.setMode(800, 600)
    
    -- Player (The spaceship)
    player = {
        x = 400, y = 550,
        width = 40, height = 40,
        speed = 300,
        radius = 20
    }
    
    -- Collectibles (The stars)
    collectibles = {}
    spawnTimer = 0
    spawnDelay = 1
    
    -- Enemy (The drone)
    enemy = {
        x = 400, y = 50,
        width = 35, height = 35,
        speed = 150,
        radius = 17.5
    }
    
    -- Game state
    score = 0
    lives = 3
    font = love.graphics.newFont(30)
    gameActive = true
    screenShake = 0
end

function love.update(dt)
    if not gameActive then return end
    
    -- 1. Player Movement (Arrow Keys or WASD)
    local move = {x = 0, y = 0}
    if love.keyboard.isDown("left", "a") then move.x = -1 end
    if love.keyboard.isDown("right", "d") then move.x = 1 end
    if love.keyboard.isDown("up", "w") then move.y = -1 end
    if love.keyboard.isDown("down", "s") then move.y = 1 end
    
    if move.x ~= 0 or move.y ~= 0 then
        local length = math.sqrt(move.x^2 + move.y^2)
        move.x = move.x / length
        move.y = move.y / length
    end
    
    player.x = player.x + move.x * player.speed * dt
    player.y = player.y + move.y * player.speed * dt
    
    -- Keep player inside the screen
    player.x = math.max(player.radius, math.min(800 - player.radius, player.x))
    player.y = math.max(player.radius, math.min(600 - player.radius, player.y))
    
    -- 2. Enemy Movement (Chases the player)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = math.sqrt(dx^2 + dy^2)
    if dist > 0 then
        enemy.x = enemy.x + (dx / dist) * enemy.speed * dt
        enemy.y = enemy.y + (dy / dist) * enemy.speed * dt
    end
    
    -- Keep enemy inside the screen
    enemy.x = math.max(enemy.radius, math.min(800 - enemy.radius, enemy.x))
    enemy.y = math.max(enemy.radius, math.min(600 - enemy.radius, enemy.y))
    
    -- 3. Enemy vs. Player Collision
    local dxp = player.x - enemy.x
    local dyp = player.y - enemy.y
    local distance = math.sqrt(dxp^2 + dyp^2)
    if distance < player.radius + enemy.radius then
        lives = lives - 1
        screenShake = 0.3
        
        if lives <= 0 then
            gameActive = false
        else
            -- Respawn player at center, enemy at a safe corner
            player.x, player.y = 400, 550
            enemy.x, enemy.y = 50, 50
        end
    end
    
    -- 4. Spawn Stars
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnDelay then
        spawnTimer = 0
        local star = {
            x = math.random(20, 780),
            y = -20,
            radius = 10,
            speed = math.random(100, 250)
        }
        table.insert(collectibles, star)
    end
    
    -- 5. Update Stars & Check Collection
    for i, star in ipairs(collectibles) do
        star.y = star.y + star.speed * dt
        
        -- Check if player collects the star
        local dxc = player.x - star.x
        local dyc = player.y - star.y
        if math.sqrt(dxc^2 + dyc^2) < player.radius + star.radius then
            table.remove(collectibles, i)
            score = score + 10
            spawnDelay = math.max(0.3, spawnDelay - 0.005)
        end
    end
    
    -- Remove stars that fall off-screen
    for i = #collectibles, 1, -1 do
        if collectibles[i].y > 600 + collectibles[i].radius then
            table.remove(collectibles, i)
        end
    end
    
    -- Screen shake effect (reduces over time)
    if screenShake > 0 then
        screenShake = screenShake - dt * 2
    end
end

function love.draw()
    -- Apply screen shake offset
    local shakeX = 0
    local shakeY = 0
    if screenShake > 0 then
        shakeX = love.math.random(-5, 5)
        shakeY = love.math.random(-5, 5)
    end
    love.graphics.translate(shakeX, shakeY)
    
    -- Draw background
    love.graphics.setBackgroundColor(0.05, 0.05, 0.15)
    
    -- Draw player (A golden ship)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.circle("fill", player.x, player.y, player.radius)
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.circle("line", player.x, player.y, player.radius + 3)
    
    -- Draw enemy (A red drone)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill", enemy.x - enemy.width/2, enemy.y - enemy.height/2, enemy.width, enemy.height, 5, 5)
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.rectangle("line", enemy.x - enemy.width/2, enemy.y - enemy.height/2, enemy.width, enemy.height, 5, 5)
    
    -- Draw stars (Collectibles)
    for _, star in ipairs(collectibles) do
        love.graphics.setColor(0.2, 0.8, 1)
        love.graphics.circle("fill", star.x, star.y, star.radius)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", star.x, star.y, star.radius + 2)
    end
    
    -- Draw UI
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 20, 20)
    love.graphics.print("Lives: " .. lives, 20, 60)
    
    -- Game Over screen
    if not gameActive then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("GAME OVER!\nFinal Score: " .. score, 0, 250, 800, "center")
        love.graphics.printf("Press 'R' to Restart", 0, 350, 800, "center")
    end
    
    love.graphics.reset()
end

function love.keypressed(key)
    if key == "r" and not gameActive then
        -- Reset the game
        gameActive = true
        score = 0
        lives = 3
        collectibles = {}
        spawnDelay = 1
        spawnTimer = 0
        player.x, player.y = 400, 550
        enemy.x, enemy.y = 50, 50
        screenShake = 0
    end
end
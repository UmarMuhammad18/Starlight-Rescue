function love.conf(t)
    t.identity = "starlight-rescue"   -- save folder name (high score lives here)
    t.version = "11.5"

    t.window.title = "Starlight Rescue"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1

    t.modules.physics = false
end

-- All tuning values in one place

return {
    width = 800,
    height = 600,

    startLives = 3,
    maxLives = 5,
    invulnTime = 1.5,           -- seconds of invulnerability after a hit

    player = {
        speed = 300,
        radius = 20,
        startX = 400,
        startY = 520,
        boostMultiplier = 1.6,
    },

    enemy = {
        radius = 17.5,
        size = 35,
        baseSpeed = 140,
        speedPerPoint = 0.12,   -- extra drone speed per point scored
        maxSpeed = 250,         -- stays below the player's speed so escape is possible
        extraDroneEvery = 250,  -- points needed for each additional drone
        maxDrones = 4,
        warpTime = 1.0,         -- seconds a new or respawned drone is harmless
    },

    stars = {
        startDelay = 1.0,
        minDelay = 0.3,
        delayStep = 0.005,      -- spawn delay shrinks by this per star collected
        minSpeed = 100,
        maxSpeed = 250,
        speedPerPoint = 0.0005, -- fall speed multiplier growth per point
        maxSpeedMultiplier = 1.6,
    },

    combo = {
        window = 1.25,          -- seconds to grab the next star before the combo drops
        starsPerLevel = 4,      -- stars needed per multiplier step
        maxMultiplier = 5,
    },

    powerups = {
        firstSpawn = 8,
        spawnEvery = 14,
        lifetime = 8,           -- seconds a power-up waits to be picked up
        duration = 7,
        shieldDuration = 12,
        magnetRange = 180,
        magnetPull = 420,
    },
}

-- Central configuration / balancing values

local Config = {}

Config.WINDOW_W = 800
Config.WINDOW_H = 600

-- Player
Config.PLAYER_SPEED = 320
Config.PLAYER_RADIUS = 18
Config.PLAYER_INVULN_TIME = 1.6
Config.PLAYER_TRAIL_MAX = 12

-- Enemy
Config.ENEMY_BASE_SPEED = 130
Config.ENEMY_SPEED_SCALE = 8          -- extra speed per difficulty level
Config.ENEMY_RADIUS = 16
Config.MAX_ENEMIES = 5
Config.ENEMY_SPAWN_SCORE = 250        -- every N points spawn an extra enemy

-- Stars
Config.STAR_BASE_SPAWN = 1.0
Config.STAR_MIN_SPAWN = 0.28
Config.STAR_SPEED_MIN = 90
Config.STAR_SPEED_MAX = 240
Config.STAR_RADIUS = 9
Config.STAR_POINTS = 10

-- Power-ups
Config.POWERUP_CHANCE = 0.12         -- chance a star becomes a power-up
Config.POWERUP_DURATION = 6.0
Config.POWERUP_TYPES = {"shield", "slow", "magnet", "mult", "life"}

-- Combo
Config.COMBO_WINDOW = 1.8            -- seconds to keep combo alive
Config.COMBO_MAX = 8

-- Difficulty
Config.DIFFICULTY_SCORE_STEP = 400   -- every N points difficulty +

-- Visual
Config.SHAKE_DECAY = 2.2
Config.BG_STAR_COUNT = 80

-- Colors (RGBA 0-1)
Config.COLOR = {
    bg          = {0.03, 0.03, 0.10, 1},
    player      = {1.00, 0.82, 0.25, 1},
    playerGlow  = {1.00, 0.95, 0.55, 0.45},
    enemy       = {1.00, 0.22, 0.22, 1},
    enemyGlow   = {1.00, 0.45, 0.45, 0.4},
    star        = {0.25, 0.85, 1.00, 1},
    starGlow    = {0.70, 0.95, 1.00, 0.5},
    shield      = {0.30, 0.90, 1.00, 0.55},
    text        = {1, 1, 1, 1},
    dim         = {0.7, 0.75, 0.85, 1},
    accent      = {1.00, 0.85, 0.30, 1},
    danger      = {1.00, 0.35, 0.35, 1},
}

return Config

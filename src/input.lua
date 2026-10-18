-- Keyboard and gamepad input

local input = {}

local DEADZONE = 0.25

local keyActions = {
    ["return"] = "confirm", kpenter = "confirm", space = "confirm",
    p = "pause", escape = "escape", r = "restart", q = "back", m = "mute",
}

local buttonActions = {
    a = "confirm", start = "pause", back = "back", y = "mute",
}

local function getGamepad()
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then return joystick end
    end
end

-- Movement direction with length <= 1 (analog sticks keep partial speed)
function input.getMovement()
    local x, y = 0, 0
    if love.keyboard.isDown("left", "a") then x = x - 1 end
    if love.keyboard.isDown("right", "d") then x = x + 1 end
    if love.keyboard.isDown("up", "w") then y = y - 1 end
    if love.keyboard.isDown("down", "s") then y = y + 1 end

    local pad = getGamepad()
    if pad then
        local ax, ay = pad:getGamepadAxis("leftx"), pad:getGamepadAxis("lefty")
        if math.abs(ax) > DEADZONE then x = x + ax end
        if math.abs(ay) > DEADZONE then y = y + ay end
        if pad:isGamepadDown("dpleft") then x = x - 1 end
        if pad:isGamepadDown("dpright") then x = x + 1 end
        if pad:isGamepadDown("dpup") then y = y - 1 end
        if pad:isGamepadDown("dpdown") then y = y + 1 end
    end

    local length = math.sqrt(x * x + y * y)
    if length > 1 then
        x, y = x / length, y / length
    end
    return x, y
end

function input.actionForKey(key)
    return keyActions[key]
end

function input.actionForButton(button)
    return buttonActions[button]
end

return input

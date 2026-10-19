-- Sound effects and music, synthesized at startup (no audio files needed)

local audio = {}

local RATE = 22050
local TAU = math.pi * 2
local MUSIC_VOLUME, MUSIC_QUIET_VOLUME = 0.5, 0.15

local sounds = {}
local music
local muted = false

local waves = {
    sine = function(phase) return math.sin(phase * TAU) end,
    square = function(phase) return (phase % 1 < 0.5) and 1 or -1 end,
    triangle = function(phase) return 1 - 4 * math.abs((phase % 1) - 0.5) end,
}

local function noise()
    return love.math.random() * 2 - 1
end

local function sweep(from, to)
    return function(p) return from + (to - from) * p end
end

local function notes(list)
    return function(p) return list[math.min(#list, math.floor(p * #list) + 1)] end
end

-- Renders a short effect. freqAt(progress) gives the pitch at 0..1 through the sound;
-- `steps` gives each of that many notes its own envelope.
local function synth(duration, volume, wave, freqAt, noiseMix, steps)
    noiseMix = noiseMix or 0
    local n = math.floor(duration * RATE)
    local noteLength = n / (steps or 1)
    local data = love.sound.newSoundData(n, RATE, 16, 1)
    local phase = 0
    for i = 0, n - 1 do
        local p = i / n
        phase = phase + freqAt(p) / RATE
        local local_p = steps and (p * steps) % 1 or p
        local attack = math.min(1, local_p * noteLength / (RATE * 0.004))
        local env = (1 - local_p) ^ 2 * attack
        local sample = wave(phase) * (1 - noiseMix) + noise() * noiseMix
        data:setSample(i, sample * env * volume)
    end
    return love.audio.newSource(data, "static")
end

local function midiToHz(note)
    return 440 * 2 ^ ((note - 69) / 12)
end

-- A looping Am-F-C-G arpeggio with a bass line and soft hi-hats
local function makeMusic()
    local bpm = 112
    local stepSamples = math.floor(60 / bpm / 2 * RATE)   -- eighth notes
    local chords = { {57, 60, 64}, {53, 57, 60}, {48, 52, 55}, {55, 59, 62} }
    local arp = { 1, 2, 3, 2, 1, 2, 3, 4 }                 -- 4 = root an octave up
    local barSamples = #arp * stepSamples
    local n = #chords * barSamples
    local data = love.sound.newSoundData(n, RATE, 16, 1)
    local arpPhase, bassPhase = 0, 0

    for i = 0, n - 1 do
        local step = math.floor(i / stepSamples)
        local q = (i % stepSamples) / stepSamples          -- progress through this step
        local chord = chords[math.floor(i / barSamples) + 1]
        local index = arp[step % #arp + 1]
        local note = index == 4 and chord[1] + 12 or chord[index]

        arpPhase = arpPhase + midiToHz(note + 12) / RATE
        local arpEnv = (1 - q) ^ 2 * math.min(1, q * stepSamples / (RATE * 0.004))

        local barQ = (i % barSamples) / barSamples
        bassPhase = bassPhase + midiToHz(chord[1] - 12) / RATE
        local bassEnv = math.min(1, barQ * barSamples / (RATE * 0.01)) * (1 - barQ) ^ 0.7

        local hat = (step % 2 == 1) and noise() * math.exp(-q * 25) * 0.05 or 0

        data:setSample(i, waves.triangle(arpPhase) * arpEnv * 0.16
            + waves.sine(bassPhase) * bassEnv * 0.22
            + hat)
    end

    local source = love.audio.newSource(data, "static")
    source:setLooping(true)
    return source
end

function audio.load()
    sounds.collect  = synth(0.12, 0.35, waves.triangle, sweep(700, 1400))
    sounds.gold     = synth(0.30, 0.22, waves.square, notes{880, 1175, 1760}, 0, 3)
    sounds.life     = synth(0.45, 0.35, waves.triangle, notes{523, 659, 784, 1047}, 0, 4)
    sounds.combo    = synth(0.16, 0.18, waves.square, notes{660, 990}, 0, 2)
    sounds.powerup  = synth(0.40, 0.20, waves.square, sweep(300, 1200))
    sounds.hit      = synth(0.40, 0.45, waves.square, sweep(320, 50), 0.5)
    sounds.shield   = synth(0.30, 0.30, waves.triangle, sweep(1400, 200), 0.2)
    sounds.drone    = synth(0.50, 0.15, waves.square, sweep(200, 520))
    sounds.start    = synth(0.36, 0.20, waves.square, notes{392, 523, 659, 784}, 0, 4)
    sounds.gameover = synth(1.20, 0.35, waves.triangle, notes{440, 392, 330, 220}, 0, 4)
    sounds.pause    = synth(0.08, 0.20, waves.sine, sweep(900, 600))

    music = makeMusic()
    music:setVolume(MUSIC_VOLUME)
end

function audio.play(name)
    -- Clone so the same effect can overlap itself
    sounds[name]:clone():play()
end

function audio.playMusic()
    music:play()
end

function audio.setMusicQuiet(quiet)
    music:setVolume(quiet and MUSIC_QUIET_VOLUME or MUSIC_VOLUME)
end

function audio.toggleMute()
    muted = not muted
    love.audio.setVolume(muted and 0 or 1)
end

function audio.isMuted()
    return muted
end

return audio

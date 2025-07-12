-- Audio management system for music and sound effects

local AudioManager = {}
AudioManager.__index = AudioManager

function AudioManager:new()
    local manager = setmetatable({}, AudioManager)
    
    manager.musicEnabled = true
    manager.sfxEnabled = true
    manager.musicVolume = 0.6
    manager.sfxVolume = 0.8
    
    -- Sound sources
    manager.sounds = {}
    manager.currentMusic = nil
    
    -- Generate procedural audio
    manager:generateAudio()
    
    return manager
end

function AudioManager:generateAudio()
    -- Generate simple tones for sound effects using SoundData
    self:generateShootSound()
    self:generateExplosionSound()
    self:generateHitSound()
    self:generateBackgroundMusic()
end

function AudioManager:generateShootSound()
    local sampleRate = 22050
    local duration = 0.1
    local samples = math.floor(sampleRate * duration)
    
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Quick laser-like beep
        local frequency = 800 + 400 * math.exp(-t * 20)
        local wave = math.sin(2 * math.pi * frequency * t) * math.exp(-t * 10)
        soundData:setSample(i, wave * 0.3)
    end
    
    self.sounds.shoot = love.audio.newSource(soundData, "static")
end

function AudioManager:generateExplosionSound()
    local sampleRate = 22050
    local duration = 0.3
    local samples = math.floor(sampleRate * duration)
    
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Explosion-like noise burst
        local noise = (math.random() - 0.5) * 2
        local envelope = math.exp(-t * 8)
        local lowFreq = math.sin(2 * math.pi * 60 * t) * 0.5
        local wave = (noise * 0.7 + lowFreq * 0.3) * envelope
        soundData:setSample(i, wave * 0.4)
    end
    
    self.sounds.explosion = love.audio.newSource(soundData, "static")
end

function AudioManager:generateHitSound()
    local sampleRate = 22050
    local duration = 0.05
    local samples = math.floor(sampleRate * duration)
    
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Sharp hit sound
        local frequency = 1200
        local wave = math.sin(2 * math.pi * frequency * t) * math.exp(-t * 50)
        soundData:setSample(i, wave * 0.2)
    end
    
    self.sounds.hit = love.audio.newSource(soundData, "static")
end

function AudioManager:generateBackgroundMusic()
    local sampleRate = 22050
    local duration = 8.0 -- 8 second loop
    local samples = math.floor(sampleRate * duration)
    
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- Simple ambient sci-fi music
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local loopTime = t % duration
        
        -- Base drone
        local drone = math.sin(2 * math.pi * 55 * t) * 0.1 -- Low A
        
        -- Melodic elements
        local melody1 = math.sin(2 * math.pi * 220 * t) * math.sin(loopTime * 0.5) * 0.05 -- A4
        local melody2 = math.sin(2 * math.pi * 330 * t) * math.sin(loopTime * 0.3) * 0.03 -- E5
        
        -- Ambient pad
        local pad = (math.sin(2 * math.pi * 110 * t) + math.sin(2 * math.pi * 165 * t)) * 0.02
        
        -- Combine all elements
        local wave = drone + melody1 + melody2 + pad
        soundData:setSample(i, wave)
    end
    
    self.currentMusic = love.audio.newSource(soundData, "static")
    self.currentMusic:setLooping(true)
    self.currentMusic:setVolume(self.musicVolume)
end

function AudioManager:playSound(soundName)
    if not self.sfxEnabled or not self.sounds[soundName] then
        return
    end
    
    -- Clone the source to allow multiple simultaneous plays
    local source = self.sounds[soundName]:clone()
    source:setVolume(self.sfxVolume)
    love.audio.play(source)
end

function AudioManager:startMusic()
    if self.musicEnabled and self.currentMusic then
        if not self.currentMusic:isPlaying() then
            love.audio.play(self.currentMusic)
        end
    end
end

function AudioManager:stopMusic()
    if self.currentMusic then
        self.currentMusic:stop()
    end
end

function AudioManager:pauseMusic()
    if self.currentMusic then
        self.currentMusic:pause()
    end
end

function AudioManager:resumeMusic()
    if self.currentMusic and self.musicEnabled then
        self.currentMusic:resume()
    end
end

function AudioManager:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    if self.currentMusic then
        self.currentMusic:setVolume(self.musicVolume)
    end
end

function AudioManager:setSfxVolume(volume)
    self.sfxVolume = math.max(0, math.min(1, volume))
end

function AudioManager:toggleMusic()
    self.musicEnabled = not self.musicEnabled
    if self.musicEnabled then
        self:startMusic()
    else
        self:stopMusic()
    end
    return self.musicEnabled
end

function AudioManager:toggleSfx()
    self.sfxEnabled = not self.sfxEnabled
    return self.sfxEnabled
end

return AudioManager
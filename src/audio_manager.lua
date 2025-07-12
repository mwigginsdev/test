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
    local duration = 16.0 -- 16 second loop for more complex patterns
    local samples = math.floor(sampleRate * duration)
    
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    -- More lively sci-fi music with rhythm and progression
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local loopTime = t % duration
        local beat = (loopTime * 1.5) % 1 -- 2 beats per second (120 BPM)
        local measure = math.floor(loopTime * 0.5) % 4 -- 4-measure cycle
        
        -- Dynamic bass line with rhythm
        local bassFreq = self:getBassNote(measure, beat)
        local bassEnv = self:getRhythmEnvelope(beat, 0.8, 0.1) -- Strong attack, quick decay
        local bass = math.sin(2 * math.pi * bassFreq * t) * bassEnv * 0.15
        
        -- Rhythmic percussion-like elements
        local kick = self:getKickDrum(beat, t) * 0.1
        local hihat = self:getHiHat(beat, t) * 0.05
        
        -- Arpeggiated chord progression
        local arpFreq = self:getArpNote(measure, beat * 8) -- 8 notes per beat
        local arpEnv = self:getArpEnvelope(beat * 8)
        local arp = math.sin(2 * math.pi * arpFreq * t) * arpEnv * 0.08
        
        -- Lead melody with more movement
        local leadFreq = self:getLeadNote(measure, loopTime)
        local leadMod = 1 + 0.001 * math.sin(math.pi * t) -- Vibrato
        local lead = math.sin(2 * math.pi * leadFreq * leadMod * t) * 0.06
        
        -- Atmospheric pad with filter-like effect
        local padLow = math.sin(2 * math.pi * 110 * t) * 0.03
        local padHigh = math.sin(2 * math.pi * 220 * t) * 0.02
        local filterMod = 0.5 + 0.5 * math.sin(2 * math.pi * 0.25 * loopTime)
        local pad = padLow + padHigh * filterMod
        
        -- Sub bass for depth
        local sub = math.sin(2 * math.pi * 55 * t) * 0.08
        
        -- Combine all elements with some saturation
        local wave = hihat + arp + pad + sub + bass
        wave = math.tanh(wave * 1.2) -- Soft saturation for warmth
        soundData:setSample(i, wave)
    end
    
    self.currentMusic = love.audio.newSource(soundData, "static")
    self.currentMusic:setLooping(true)
    self.currentMusic:setVolume(self.musicVolume)
end

-- Helper functions for musical elements
function AudioManager:getBassNote(measure, beat)
    local notes = {
        {55, 65.4, 55, 73.4},   -- A, E, A, D (measure 0)
        {49, 58.3, 49, 65.4},   -- G, Bb, G, E (measure 1)
        {61.7, 73.4, 61.7, 82.4}, -- C#, D, C#, F# (measure 2)
        {55, 65.4, 73.4, 82.4}     -- A, E, D, F# (measure 3)
    }
    local noteIndex = math.floor(beat * 4) + 1
    return notes[measure + 1][math.min(noteIndex, 4)]
end

function AudioManager:getRhythmEnvelope(beat, attack, sustain)
    local phase = beat % 1
    if phase < 0.1 then
        return attack * (phase / 0.1)
    else
        return sustain * math.exp(-(phase - 0.1) * 8)
    end
end

function AudioManager:getKickDrum(beat, t)
    local phase = beat % 1
    if phase < 0.1 then
        local freq = 60 * (1 - phase * 8)
        return math.sin(2 * math.pi * freq * t) * (1 - phase * 10)
    end
    return 0
end

function AudioManager:getHiHat(beat, t)
    local phase = (beat * 4) % 1
    if phase < 0.05 then
        local noise = (math.random() - 0.5) * 2
        return noise * (1 - phase * 20)
    end
    return 0
end

function AudioManager:getArpNote(measure, arpBeat)
    local scales = {
        {220, 277.2, 329.6, 440},      -- A minor arp (measure 0)
        {196, 246.9, 293.7, 392},      -- G minor arp (measure 1)  
        {246.9, 311.1, 369.9, 493.9}, -- C# minor arp (measure 2)
        {220, 277.2, 293.7, 369.9}    -- A, C#, D, F# (measure 3)
    }
    local noteIndex = (math.floor(arpBeat) % 4) + 1
    return scales[measure + 1][noteIndex]
end

function AudioManager:getArpEnvelope(arpBeat)
    local phase = arpBeat % 1
    return math.exp(-phase * 6) * (0.3 + 0.7 * math.sin(math.pi * phase))
end

function AudioManager:getLeadNote(measure, loopTime)
    local melodies = {
        440,  -- A
        494,  -- B
        523,  -- C
        587,  -- D
        523,  -- C
        494,  -- B
        440,  -- A
        392   -- G
    }
    local noteIndex = math.floor(loopTime * 0.5) % 8 + 1
    local bendAmount = math.sin(2 * math.pi * loopTime * 0.125) * 0.02
    return melodies[noteIndex] * (1 + bendAmount)
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
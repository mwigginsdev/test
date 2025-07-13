-- Settings screen module

local Settings = {}
Settings.__index = Settings

function Settings:new(game)
    local settings = setmetatable({}, Settings)
    
    settings.game = game
    settings.isVisible = false
    settings.selectedOption = 1
    settings.options = {
        {name = "Music Volume", value = "musicVolume", min = 0, max = 1, step = 0.1},
        {name = "SFX Volume", value = "sfxVolume", min = 0, max = 1, step = 0.1},
        {name = "Ship Rotation Speed", value = "rotationSpeed", min = 0.5, max = 5, step = 0.1},
        {name = "Camera Smoothing", value = "cameraSmoothing", min = 1, max = 10, step = 0.5},
        {name = "Auto-Shoot", value = "autoShoot", type = "boolean"},
        {name = "Music Enabled", value = "musicEnabled", type = "boolean"},
        {name = "SFX Enabled", value = "sfxEnabled", type = "boolean"}
    }
    
    -- Default settings
    settings.values = {
        musicVolume = 0.6,
        sfxVolume = 0.8,
        rotationSpeed = 2.0,
        cameraSmoothing = 5.0,
        autoShoot = false,
        musicEnabled = true,
        sfxEnabled = true
    }
    
    return settings
end

function Settings:toggle()
    self.isVisible = not self.isVisible
    if self.isVisible then
        self:loadCurrentSettings()
    else
        self:applySettings()
    end
end

function Settings:loadCurrentSettings()
    -- Load current game settings
    self.values.musicVolume = self.game.audioManager.musicVolume
    self.values.sfxVolume = self.game.audioManager.sfxVolume
    self.values.autoShoot = self.game.autoShoot
    self.values.musicEnabled = self.game.audioManager.musicEnabled
    self.values.sfxEnabled = self.game.audioManager.sfxEnabled
    self.values.cameraSmoothing = self.game.camera.smoothing
    self.values.rotationSpeed = self.game.camera.rotationSpeed
end

function Settings:applySettings()
    -- Apply settings to game
    self.game.audioManager:setMusicVolume(self.values.musicVolume)
    self.game.audioManager:setSfxVolume(self.values.sfxVolume)
    self.game.autoShoot = self.values.autoShoot
    self.game.audioManager.musicEnabled = self.values.musicEnabled
    self.game.audioManager.sfxEnabled = self.values.sfxEnabled
    self.game.camera.smoothing = self.values.cameraSmoothing
    self.game.camera.rotationSpeed = self.values.rotationSpeed
    
    if self.values.musicEnabled then
        self.game.audioManager:startMusic()
    else
        self.game.audioManager:stopMusic()
    end
end

function Settings:keypressed(key)
    if not self.isVisible then return end
    
    if key == "up" then
        self.selectedOption = math.max(1, self.selectedOption - 1)
    elseif key == "down" then
        self.selectedOption = math.min(#self.options, self.selectedOption + 1)
    elseif key == "left" then
        self:adjustValue(-1)
    elseif key == "right" then
        self:adjustValue(1)
    elseif key == "return" or key == "space" then
        self:toggleValue()
    elseif key == "escape" then
        self:toggle()
    end
end

function Settings:adjustValue(direction)
    local option = self.options[self.selectedOption]
    local currentValue = self.values[option.value]
    
    if option.type == "boolean" then
        self.values[option.value] = not currentValue
    else
        local newValue = currentValue + (direction * option.step)
        self.values[option.value] = math.max(option.min, math.min(option.max, newValue))
    end
end

function Settings:toggleValue()
    local option = self.options[self.selectedOption]
    if option.type == "boolean" then
        self.values[option.value] = not self.values[option.value]
    end
end

function Settings:draw()
    if not self.isVisible then return end
    
    -- Background overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Settings panel
    local panelWidth = 600
    local panelHeight = 500
    local panelX = (love.graphics.getWidth() - panelWidth) / 2
    local panelY = (love.graphics.getHeight() - panelHeight) / 2
    
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("SETTINGS", panelX + 20, panelY + 20, 0, 2.5, 2.5)
    
    -- Options
    local startY = panelY + 80
    for i, option in ipairs(self.options) do
        local y = startY + (i - 1) * 35
        local isSelected = (i == self.selectedOption)
        
        -- Highlight selected option
        if isSelected then
            love.graphics.setColor(0.2, 0.4, 0.6, 0.5)
            love.graphics.rectangle("fill", panelX + 10, y - 5, panelWidth - 20, 30)
        end
        
        -- Option name
        love.graphics.setColor(isSelected and {1, 1, 1} or {0.7, 0.7, 0.7})
        love.graphics.print(option.name .. ":", panelX + 20, y, 0, 1.2, 1.2)
        
        -- Option value
        local valueStr = self:getValueString(option)
        love.graphics.setColor(isSelected and {0, 1, 1} or {0.8, 0.8, 0.8})
        love.graphics.print(valueStr, panelX + 300, y, 0, 1.2, 1.2)
    end
    
    -- Controls help
    love.graphics.setColor(0.6, 0.6, 0.6)
    local helpY = panelY + panelHeight - 80
    love.graphics.print("↑↓ Navigate   ←→ Adjust   SPACE Toggle   ESC Close", panelX + 20, helpY, 0, 1, 1)
end

function Settings:getValueString(option)
    local value = self.values[option.value]
    
    if option.type == "boolean" then
        return value and "ON" or "OFF"
    else
        return string.format("%.1f", value)
    end
end

return Settings
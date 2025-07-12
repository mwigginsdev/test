-- Space Station entity class

local SpaceStation = {}
SpaceStation.__index = SpaceStation

function SpaceStation:new(x, y, stationType)
    local station = setmetatable({}, SpaceStation)
    
    station.x = x
    station.y = y
    station.type = stationType or "research" -- research, military, trading, mining
    station.radius = 80
    station.health = 500
    station.maxHealth = 500
    station.shield = 100
    station.maxShield = 100
    station.shieldRegenRate = 20 -- per second
    
    -- Visual properties
    station.rotation = 0
    station.rotationSpeed = 0.2 -- slow rotation
    station.glowIntensity = 0.8
    station.glowPhase = 0
    
    -- Station-specific properties
    station:setStationProperties()
    
    -- Docking system
    station.dockingBays = {}
    station.dockedShips = {}
    station.dockingRange = 120
    
    -- Station modules (visual components)
    station.modules = station:generateModules()
    
    -- Communication system
    station.commRange = 300
    station.isHailing = false
    station.hailMessage = station:getHailMessage()
    
    return station
end

function SpaceStation:setStationProperties()
    if self.type == "research" then
        self.color = {0.2, 0.8, 1.0}
        self.services = {"repair", "upgrade", "information"}
        self.hostilityLevel = 0 -- Peaceful
    elseif self.type == "military" then
        self.color = {1.0, 0.3, 0.3}
        self.services = {"repair", "weapons", "defense"}
        self.hostilityLevel = 1 -- Neutral but armed
        self.weapons = self:generateDefenseWeapons()
    elseif self.type == "trading" then
        self.color = {1.0, 1.0, 0.3}
        self.services = {"repair", "trade", "fuel"}
        self.hostilityLevel = 0 -- Peaceful
    elseif self.type == "mining" then
        self.color = {0.8, 0.5, 0.2}
        self.services = {"repair", "resources"}
        self.hostilityLevel = 0 -- Peaceful
    end
end

function SpaceStation:generateModules()
    local modules = {}
    local numModules = math.random(4, 8)
    
    for i = 1, numModules do
        local angle = (i / numModules) * 2 * math.pi
        local distance = math.random(40, 70)
        table.insert(modules, {
            x = math.cos(angle) * distance,
            y = math.sin(angle) * distance,
            size = math.random(8, 15),
            type = math.random(1, 3) -- Different module types
        })
    end
    
    return modules
end

function SpaceStation:generateDefenseWeapons()
    local weapons = {}
    for i = 1, 4 do
        local angle = (i / 4) * 2 * math.pi
        table.insert(weapons, {
            x = math.cos(angle) * 60,
            y = math.sin(angle) * 60,
            angle = angle,
            lastShot = 0,
            fireRate = 2.0
        })
    end
    return weapons
end

function SpaceStation:getHailMessage()
    local messages = {
        research = "Research Station Alpha-7: Welcome, traveler. Our facilities are open for scientific collaboration.",
        military = "Military Outpost Gamma: State your business in this sector.",
        trading = "Trading Hub Central: Dock with us for the finest goods in the galaxy!",
        mining = "Mining Station Beta: Seeking rare minerals? We have what you need."
    }
    return messages[self.type] or "Space Station: Greetings, traveler."
end

function SpaceStation:update(dt, player)
    -- Rotate station slowly
    self.rotation = self.rotation + self.rotationSpeed * dt
    
    -- Update glow effect
    self.glowPhase = self.glowPhase + dt * 2
    self.glowIntensity = 0.8 + 0.2 * math.sin(self.glowPhase)
    
    -- Regenerate shields if not at max
    if self.shield < self.maxShield then
        self.shield = math.min(self.maxShield, self.shield + self.shieldRegenRate * dt)
    end
    
    -- Check for player proximity
    local distance = math.sqrt((player.x - self.x)^2 + (player.y - self.y)^2)
    
    -- Communication range check
    if distance <= self.commRange and not self.isHailing then
        self.isHailing = true
        -- Could trigger UI message here
    elseif distance > self.commRange then
        self.isHailing = false
    end
    
    -- Docking range check
    if distance <= self.dockingRange then
        -- Player is in docking range
        -- Could show docking prompt
    end
end

function SpaceStation:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    
    -- Draw shield effect if shields are up
    if self.shield > 0 then
        local shieldAlpha = (self.shield / self.maxShield) * 0.3
        love.graphics.setColor(0.2, 0.8, 1.0, shieldAlpha)
        love.graphics.circle("line", 0, 0, self.radius + 10)
    end
    
    -- Draw main station structure
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1.0)
    
    -- Central hub
    love.graphics.circle("fill", 0, 0, 25)
    love.graphics.setColor(self.color[1] * 0.7, self.color[2] * 0.7, self.color[3] * 0.7, 1.0)
    love.graphics.circle("line", 0, 0, 25)
    
    -- Draw modules
    for _, module in ipairs(self.modules) do
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.8)
        
        if module.type == 1 then
            -- Rectangular modules
            love.graphics.rectangle("fill", module.x - module.size/2, module.y - module.size/2, module.size, module.size)
        elseif module.type == 2 then
            -- Circular modules
            love.graphics.circle("fill", module.x, module.y, module.size/2)
        else
            -- Solar panel-like modules
            love.graphics.rectangle("fill", module.x - module.size, module.y - 3, module.size * 2, 6)
        end
        
        -- Connection lines to central hub
        love.graphics.setColor(self.color[1] * 0.5, self.color[2] * 0.5, self.color[3] * 0.5, 0.7)
        love.graphics.line(0, 0, module.x, module.y)
    end
    
    -- Draw weapons if military station
    if self.type == "military" and self.weapons then
        for _, weapon in ipairs(self.weapons) do
            love.graphics.setColor(1.0, 0.5, 0.5, 1.0)
            love.graphics.circle("fill", weapon.x, weapon.y, 5)
        end
    end
    
    -- Draw station glow effect
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.glowIntensity * 0.3)
    love.graphics.circle("line", 0, 0, self.radius)
    love.graphics.circle("line", 0, 0, self.radius + 5)
    
    love.graphics.pop()
    
    -- Draw station name/type above station
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(string.upper(self.type) .. " STATION", self.x - 40, self.y - self.radius - 20)
    
    -- Draw health/shield bars
    self:drawStatusBars()
end

function SpaceStation:drawStatusBars()
    local barWidth = 60
    local barHeight = 4
    local barX = self.x - barWidth/2
    local barY = self.y + self.radius + 10
    
    -- Health bar background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Health bar
    local healthPercent = self.health / self.maxHealth
    love.graphics.setColor(1 - healthPercent, healthPercent, 0, 0.9)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
    
    -- Shield bar background
    barY = barY + barHeight + 2
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- Shield bar
    local shieldPercent = self.shield / self.maxShield
    love.graphics.setColor(0.2, 0.8, 1.0, 0.9)
    love.graphics.rectangle("fill", barX, barY, barWidth * shieldPercent, barHeight)
end

function SpaceStation:takeDamage(damage)
    if self.shield > 0 then
        -- Shields absorb damage first
        local shieldDamage = math.min(damage, self.shield)
        self.shield = self.shield - shieldDamage
        damage = damage - shieldDamage
    end
    
    if damage > 0 then
        self.health = self.health - damage
    end
    
    return self.health <= 0
end

function SpaceStation:isPlayerInDockingRange(player)
    local distance = math.sqrt((player.x - self.x)^2 + (player.y - self.y)^2)
    return distance <= self.dockingRange
end

function SpaceStation:isPlayerInCommRange(player)
    local distance = math.sqrt((player.x - self.x)^2 + (player.y - self.y)^2)
    return distance <= self.commRange
end

function SpaceStation:canProvideService(serviceName)
    for _, service in ipairs(self.services) do
        if service == serviceName then
            return true
        end
    end
    return false
end

return SpaceStation
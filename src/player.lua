-- Player ship class

local Player = {}
Player.__index = Player

function Player:new(x, y)
    local player = setmetatable({}, Player)
    
    player.x = x
    player.y = y
    player.radius = 15
    player.speed = 300
    player.health = 100
    player.maxHealth = 100
    
    -- RPG elements
    player.level = 1
    player.experience = 0
    player.experienceToNext = 100
    
    -- Equipment slots
    player.weapon1 = nil
    player.weapon2 = nil
    player.weapon3 = nil
    player.shield = nil
    player.engine = nil
    
    -- Crew slots
    player.crew = {nil, nil, nil} -- 3 crew slots
    
    -- Inventory
    player.inventory = {}
    player.credits = 1000
    
    -- Base weapon properties (when no weapon equipped)
    player.fireRate = 0.15
    player.lastShot = 0
    player.weaponType = 1 -- 1 = single, 2 = spread, 3 = rapid
    
    -- Visual properties
    player.angle = 0
    player.rotation = 0 -- Player's facing direction
    player.thrustParticles = {}
    
    return player
end

function Player:getEffectiveStats()
    -- Calculate final stats based on equipment and crew
    local stats = {
        speed = self.speed,
        fireRate = self.fireRate,
        damage = 20, -- base damage
        shieldCapacity = 0,
        shieldRegen = 0
    }
    
    -- Apply engine bonuses
    if self.engine then
        stats.speed = stats.speed + self.engine.stats.speedBonus
    end
    
    -- Apply weapon stats (use best weapon for now)
    local bestWeapon = self.weapon1 or self.weapon2 or self.weapon3
    if bestWeapon then
        stats.damage = bestWeapon.stats.damage
        stats.fireRate = bestWeapon.stats.fireRate
    end
    
    -- Apply shield stats
    if self.shield then
        stats.shieldCapacity = self.shield.stats.capacity
        stats.shieldRegen = self.shield.stats.regenRate
    end
    
    -- Apply crew bonuses
    for _, crew in ipairs(self.crew) do
        if crew then
            if crew.stats.skill == "speed" then
                stats.speed = stats.speed * (1 + crew.stats.bonus)
            elseif crew.stats.skill == "damage" then
                stats.damage = stats.damage * (1 + crew.stats.bonus)
            elseif crew.stats.skill == "repair" then
                stats.shieldRegen = stats.shieldRegen * (1 + crew.stats.bonus)
            end
        end
    end
    
    return stats
end

function Player:equipItem(item, slot)
    if item.type == "weapon" then
        if slot == 1 then self.weapon1 = item
        elseif slot == 2 then self.weapon2 = item
        elseif slot == 3 then self.weapon3 = item
        end
    elseif item.type == "shield" then
        self.shield = item
    elseif item.type == "engine" then
        self.engine = item
    elseif item.type == "crew" then
        if slot >= 1 and slot <= 3 then
            self.crew[slot] = item
        end
    end
end

function Player:addToInventory(item)
    table.insert(self.inventory, item)
end

function Player:gainExperience(amount)
    self.experience = self.experience + amount
    while self.experience >= self.experienceToNext do
        self.experience = self.experience - self.experienceToNext
        self.level = self.level + 1
        self.experienceToNext = math.floor(self.experienceToNext * 1.5)
        self.maxHealth = self.maxHealth + 20
        self.health = self.maxHealth -- Full heal on level up
        print("LEVEL UP! Now level " .. self.level)
    end
end

function Player:update(dt)
    -- Handle rotation input
    if love.keyboard.isDown('q') then
        self.rotation = self.rotation - 2 * dt -- Rotate left
    end
    if love.keyboard.isDown('e') then
        self.rotation = self.rotation + 2 * dt -- Rotate right
    end
    
    -- Handle movement relative to player rotation
    local dx, dy = 0, 0
    
    if love.keyboard.isDown('w', 'up') then
        dx = dx - 1
    end
    if love.keyboard.isDown('s', 'down') then
        dx = dx + 1
    end
    if love.keyboard.isDown('a', 'left') then
        dy = dy - 1
    end
    if love.keyboard.isDown('d', 'right') then
        dy = dy + 1
    end
    
    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.707
        dy = dy * 0.707
    end
    
    -- Rotate movement vector by player rotation
    -- Forward/backward (dy) and left/right (dx) relative to ship's facing
    local rotatedDx = dx * math.cos(self.rotation + math.pi/2) + dy * math.cos(self.rotation)
    local rotatedDy = dx * math.sin(self.rotation + math.pi/2) + dy * math.sin(self.rotation)
    
    -- Update position (no screen boundaries - infinite world)
    self.x = self.x + rotatedDx * self.speed * dt
    self.y = self.y + rotatedDy * self.speed * dt
    
    -- Update weapon cooldown
    self.lastShot = self.lastShot + dt
    
    -- Update thrust particles
    if dx ~= 0 or dy ~= 0 then
        self:createThrustParticles(dt)
    end
    
    for i = #self.thrustParticles, 1, -1 do
        local particle = self.thrustParticles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        if particle.life <= 0 then
            table.remove(self.thrustParticles, i)
        end
    end
end

function Player:createThrustParticles(dt)
    if #self.thrustParticles < 20 then
        -- Create thrust particles behind the player based on rotation
        -- Back of ship is opposite to front (rotation - π/2 + π = rotation + π/2)
        local thrustAngle = self.rotation + math.pi/2 -- Back of ship
        local thrustDistance = self.radius + 5
        
        table.insert(self.thrustParticles, {
            x = self.x + math.cos(thrustAngle) * thrustDistance + math.random(-5, 5),
            y = self.y + math.sin(thrustAngle) * thrustDistance + math.random(-5, 5),
            vx = math.cos(thrustAngle) * math.random(30, 60) + math.random(-20, 20),
            vy = math.sin(thrustAngle) * math.random(30, 60) + math.random(-20, 20),
            life = math.random(0.2, 0.5),
            maxLife = 0.5
        })
    end
end

function Player:shoot(angle, bulletManager)
    if self.lastShot >= self.fireRate then
        self.lastShot = 0
        
        -- Calculate bullet spawn position at front of rotated ship
        -- Ship's front points at (0, -radius) in local coords, so world angle is rotation - π/2
        local spawnDistance = self.radius
        local frontAngle = self.rotation - math.pi/2
        local spawnX = self.x + math.cos(frontAngle) * spawnDistance
        local spawnY = self.y + math.sin(frontAngle) * spawnDistance
        
        if self.weaponType == 1 then
            -- Single shot
            bulletManager:addPlayerBullet(spawnX, spawnY, angle, 500, 25)
        elseif self.weaponType == 2 then
            -- Spread shot
            for i = -1, 1 do
                local spreadAngle = angle + i * 0.3
                bulletManager:addPlayerBullet(spawnX, spawnY, spreadAngle, 450, 15)
            end
        elseif self.weaponType == 3 then
            -- Rapid fire
            bulletManager:addPlayerBullet(spawnX, spawnY, angle, 600, 12)
        end
        
        return true -- Successfully shot
    end
    return false -- Couldn't shoot (cooldown)
end

function Player:takeDamage(damage)
    self.health = math.max(0, self.health - damage)
end

function Player:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    
    -- Draw thrust particles
    for _, particle in ipairs(self.thrustParticles) do
        local alpha = particle.life / particle.maxLife
        love.graphics.setColor(0.2, 0.5, 1, alpha)
        love.graphics.circle('fill', particle.x - self.x, particle.y - self.y, 2)
    end
    
    -- Draw ship body (sci-fi triangle)
    love.graphics.setColor(0.7, 0.9, 1) -- Light blue
    love.graphics.polygon('fill', 
        0, -self.radius,        -- Top point (forward)
        -self.radius*0.6, self.radius*0.8,   -- Bottom left
        self.radius*0.6, self.radius*0.8     -- Bottom right
    )
    
    -- Draw ship core
    love.graphics.setColor(0, 1, 1) -- Cyan
    love.graphics.circle('fill', 0, 0, self.radius * 0.3)
    
    -- Draw ship outline
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon('line', 
        0, -self.radius,
        -self.radius*0.6, self.radius*0.8,
        self.radius*0.6, self.radius*0.8
    )
    
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
end

return Player
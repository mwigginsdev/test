-- Individual enemy class

local Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y, type, wave)
    local enemy = setmetatable({}, Enemy)
    
    enemy.x = x
    enemy.y = y
    enemy.type = type or 'scout'
    enemy.wave = wave or 1
    
    -- Set properties based on type
    if type == 'scout' then
        enemy.radius = 10
        enemy.health = 25
        enemy.maxHealth = 25
        enemy.speed = 120
        enemy.points = 10
        enemy.color = {0.8, 0.2, 0.2} -- Red
        enemy.fireRate = 1.5
        enemy.damage = 15
    elseif type == 'fighter' then
        enemy.radius = 15
        enemy.health = 50
        enemy.maxHealth = 50
        enemy.speed = 80
        enemy.points = 25
        enemy.color = {0.8, 0.4, 0.2} -- Orange
        enemy.fireRate = 1.0
        enemy.damage = 20
    elseif type == 'bomber' then
        enemy.radius = 20
        enemy.health = 80
        enemy.maxHealth = 80
        enemy.speed = 50
        enemy.points = 50
        enemy.color = {0.6, 0.2, 0.8} -- Purple
        enemy.fireRate = 2.0
        enemy.damage = 30
    end
    
    -- Scale with wave number
    enemy.health = math.floor(enemy.health * (1 + wave * 0.2))
    enemy.maxHealth = enemy.health
    enemy.speed = enemy.speed * (1 + wave * 0.1)
    
    enemy.lastShot = 0
    enemy.angle = 0
    enemy.targetAngle = 0
    enemy.behaviorTimer = 0
    enemy.behavior = 'approach'
    
    return enemy
end

function Enemy:update(dt, player, bulletManager)
    self.lastShot = self.lastShot + dt
    self.behaviorTimer = self.behaviorTimer + dt
    
    -- AI behavior based on type
    if self.type == 'scout' then
        self:scoutBehavior(dt, player)
    elseif self.type == 'fighter' then
        self:fighterBehavior(dt, player)
    elseif self.type == 'bomber' then
        self:bomberBehavior(dt, player)
    end
    
    -- Update position
    self.x = self.x + math.cos(self.angle) * self.speed * dt
    self.y = self.y + math.sin(self.angle) * self.speed * dt
    
    -- Shooting
    if self:canShoot(player) then
        self:shoot(player, bulletManager)
    end
end

function Enemy:scoutBehavior(dt, player)
    -- Quick, erratic movement
    if self.behaviorTimer > 2 then
        self.behaviorTimer = 0
        self.targetAngle = math.random() * math.pi * 2
    end
    
    -- Smooth angle transition
    local angleDiff = self.targetAngle - self.angle
    if angleDiff > math.pi then angleDiff = angleDiff - 2 * math.pi end
    if angleDiff < -math.pi then angleDiff = angleDiff + 2 * math.pi end
    
    self.angle = self.angle + angleDiff * dt * 3
end

function Enemy:fighterBehavior(dt, player)
    -- Move towards player, then strafe
    local dx = player.x - self.x
    local dy = player.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance > 200 then
        -- Move towards player
        self.targetAngle = math.atan2(dy, dx)
    else
        -- Strafe around player
        self.targetAngle = math.atan2(dy, dx) + math.pi / 2
        if self.behaviorTimer > 3 then
            self.behaviorTimer = 0
            self.targetAngle = self.targetAngle + math.pi
        end
    end
    
    -- Smooth angle transition
    local angleDiff = self.targetAngle - self.angle
    if angleDiff > math.pi then angleDiff = angleDiff - 2 * math.pi end
    if angleDiff < -math.pi then angleDiff = angleDiff + 2 * math.pi end
    
    self.angle = self.angle + angleDiff * dt * 2
end

function Enemy:bomberBehavior(dt, player)
    -- Slow, deliberate movement towards player
    local dx = player.x - self.x
    local dy = player.y - self.y
    self.targetAngle = math.atan2(dy, dx)
    
    -- Very smooth movement
    local angleDiff = self.targetAngle - self.angle
    if angleDiff > math.pi then angleDiff = angleDiff - 2 * math.pi end
    if angleDiff < -math.pi then angleDiff = angleDiff + 2 * math.pi end
    
    self.angle = self.angle + angleDiff * dt
end

function Enemy:canShoot(player)
    if self.lastShot < self.fireRate then
        return false
    end
    
    local dx = player.x - self.x
    local dy = player.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance < 400 -- Only shoot if player is close enough
end

function Enemy:shoot(player, bulletManager)
    self.lastShot = 0
    
    local dx = player.x - self.x
    local dy = player.y - self.y
    local angle = math.atan2(dy, dx)
    
    if bulletManager then
        if self.type == 'scout' then
            bulletManager:addEnemyBullet(self.x, self.y, angle, 250, self.damage)
        elseif self.type == 'fighter' then
            -- Spread shot
            for i = -1, 1 do
                local spreadAngle = angle + i * 0.2
                bulletManager:addEnemyBullet(self.x, self.y, spreadAngle, 200, self.damage)
            end
        elseif self.type == 'bomber' then
            -- Slow but powerful shot
            bulletManager:addEnemyBullet(self.x, self.y, angle, 150, self.damage)
        end
    end
end

function Enemy:takeDamage(damage)
    self.health = self.health - damage
end

function Enemy:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- Draw enemy ship based on type
    love.graphics.setColor(self.color)
    
    if self.type == 'scout' then
        -- Small diamond shape
        love.graphics.polygon('fill', 
            0, -self.radius,
            self.radius, 0,
            0, self.radius,
            -self.radius, 0
        )
    elseif self.type == 'fighter' then
        -- Triangular fighter
        love.graphics.polygon('fill',
            0, -self.radius,
            -self.radius * 0.8, self.radius,
            self.radius * 0.8, self.radius
        )
    elseif self.type == 'bomber' then
        -- Large hexagonal bomber
        local points = {}
        for i = 0, 5 do
            local angle = i * math.pi / 3
            table.insert(points, math.cos(angle) * self.radius)
            table.insert(points, math.sin(angle) * self.radius)
        end
        love.graphics.polygon('fill', points)
    end
    
    -- Draw health bar for damaged enemies
    local healthPercent = self.health / self.maxHealth
    if healthPercent < 1 then
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle('fill', -self.radius, -self.radius - 8, self.radius * 2, 4)
        love.graphics.setColor(1, healthPercent, 0)
        love.graphics.rectangle('fill', -self.radius, -self.radius - 8, self.radius * 2 * healthPercent, 4)
    end
    
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)
end

return Enemy
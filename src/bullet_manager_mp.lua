-- Multiplayer-aware Bullet Manager
-- Handles both local (predicted) and server-authoritative bullets

local BulletManager = require('src.bullet_manager')

local BulletManagerMP = {}
BulletManagerMP.__index = BulletManagerMP

-- Inherit from BulletManager
setmetatable(BulletManagerMP, {__index = BulletManager})

function BulletManagerMP:new()
    local manager = BulletManager:new()
    setmetatable(manager, BulletManagerMP)
    
    -- Server bullets (authoritative)
    manager.serverBullets = {}
    
    -- Local prediction bullets (for responsiveness)
    manager.predictedBullets = {}
    
    -- Network reconciliation
    manager.lastServerUpdate = 0
    
    return manager
end

function BulletManagerMP:updateServerBullets(serverBullets)
    -- Clear old server bullets
    self.serverBullets = {}
    
    -- Add new server bullets
    for _, bulletData in ipairs(serverBullets) do
        local bullet = {
            id = bulletData.id,
            x = bulletData.x,
            y = bulletData.y,
            angle = bulletData.angle,
            speed = 500, -- Default speed
            damage = 25, -- Default damage
            radius = 3,
            active = true,
            playerId = bulletData.playerId,
            isServerBullet = true
        }
        table.insert(self.serverBullets, bullet)
    end
    
    self.lastServerUpdate = love.timer.getTime()
end

function BulletManagerMP:addPredictedBullet(x, y, angle, speed, damage, playerId)
    -- Add bullet for immediate client feedback
    local bullet = {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        speed = speed,
        damage = damage,
        radius = 3,
        active = true,
        color = {0, 1, 1}, -- Cyan for local player
        playerId = playerId,
        isPredicted = true,
        createdAt = love.timer.getTime()
    }
    
    table.insert(self.predictedBullets, bullet)
end

function BulletManagerMP:update(dt, player)
    -- Update regular bullets (single player mode)
    BulletManager.update(self, dt, player)
    
    -- Update predicted bullets
    for i = #self.predictedBullets, 1, -1 do
        local bullet = self.predictedBullets[i]
        
        bullet.x = bullet.x + bullet.vx * dt
        bullet.y = bullet.y + bullet.vy * dt
        
        -- Remove old predicted bullets
        if love.timer.getTime() - bullet.createdAt > 3.0 then
            table.remove(self.predictedBullets, i)
        end
    end
    
    -- Server bullets don't need movement update (already positioned by server)
    -- Just remove old server bullets if server hasn't updated recently
    if love.timer.getTime() - self.lastServerUpdate > 1.0 then
        self.serverBullets = {}
    end
end

function BulletManagerMP:draw()
    -- Draw regular bullets (single player)
    BulletManager.draw(self)
    
    -- Draw predicted bullets (local player feedback)
    love.graphics.setColor(0, 1, 1) -- Cyan
    for _, bullet in ipairs(self.predictedBullets) do
        if bullet.active then
            love.graphics.circle('fill', bullet.x, bullet.y, bullet.radius)
        end
    end
    
    -- Draw server bullets (other players)
    for _, bullet in ipairs(self.serverBullets) do
        if bullet.active then
            -- Different colors for different players
            if bullet.playerId then
                local hue = (bullet.playerId * 60) % 360
                local r, g, b = self:hsvToRgb(hue, 0.8, 1.0)
                love.graphics.setColor(r, g, b)
            else
                love.graphics.setColor(1, 0.3, 0.3) -- Red default
            end
            love.graphics.circle('fill', bullet.x, bullet.y, bullet.radius)
        end
    end
    
    love.graphics.setColor(1, 1, 1) -- Reset color
end

function BulletManagerMP:hsvToRgb(h, s, v)
    -- Convert HSV to RGB for bullet colors
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local remainder = i % 6
    if remainder == 0 then
        r, g, b = v, t, p
    elseif remainder == 1 then
        r, g, b = q, v, p
    elseif remainder == 2 then
        r, g, b = p, v, t
    elseif remainder == 3 then
        r, g, b = p, q, v
    elseif remainder == 4 then
        r, g, b = t, p, v
    elseif remainder == 5 then
        r, g, b = v, p, q
    end
    
    return r, g, b
end

function BulletManagerMP:getAllBullets()
    -- Return all bullets for collision detection
    local allBullets = {}
    
    -- Add regular bullets
    for _, bullet in ipairs(self.playerBullets) do
        table.insert(allBullets, bullet)
    end
    
    for _, bullet in ipairs(self.enemyBullets) do
        table.insert(allBullets, bullet)
    end
    
    -- Add predicted bullets
    for _, bullet in ipairs(self.predictedBullets) do
        table.insert(allBullets, bullet)
    end
    
    -- Add server bullets
    for _, bullet in ipairs(self.serverBullets) do
        table.insert(allBullets, bullet)
    end
    
    return allBullets
end

-- Check collision with server bullets
function BulletManagerMP:checkServerBulletCollisions(object, clientId)
    local hits = {}
    
    for _, bullet in ipairs(self.serverBullets) do
        if bullet.active and bullet.playerId ~= clientId then
            local dx = bullet.x - object.x
            local dy = bullet.y - object.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < (bullet.radius + object.radius) then
                table.insert(hits, bullet)
                bullet.active = false
            end
        end
    end
    
    return hits
end

return BulletManagerMP
-- Bullet management system

local BulletManager = {}
BulletManager.__index = BulletManager

function BulletManager:new()
    local manager = setmetatable({}, BulletManager)
    
    manager.playerBullets = {}
    manager.enemyBullets = {}
    
    return manager
end

function BulletManager:addPlayerBullet(x, y, angle, speed, damage)
    table.insert(self.playerBullets, {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        damage = damage,
        radius = 3,
        active = true,
        type = 'player'
    })
end

function BulletManager:addEnemyBullet(x, y, angle, speed, damage)
    table.insert(self.enemyBullets, {
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        damage = damage,
        radius = 4,
        active = true,
        type = 'enemy'
    })
end

function BulletManager:update(dt, player)
    
    -- Update player bullets
    for i = #self.playerBullets, 1, -1 do
        local bullet = self.playerBullets[i]
        
        if bullet.active then
            bullet.x = bullet.x + bullet.vx * dt
            bullet.y = bullet.y + bullet.vy * dt
            
            -- Remove bullets that travel too far from player
            if player then
                local dx = bullet.x - player.x
                local dy = bullet.y - player.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance > 600 then
                    table.remove(self.playerBullets, i)
                end
            else
                table.remove(self.playerBullets, i)
            end
        else
            table.remove(self.playerBullets, i)
        end
    end
    
    -- Update enemy bullets
    for i = #self.enemyBullets, 1, -1 do
        local bullet = self.enemyBullets[i]
        
        if bullet.active then
            bullet.x = bullet.x + bullet.vx * dt
            bullet.y = bullet.y + bullet.vy * dt
            
            -- Remove bullets that travel too far from player
            if player then
                local dx = bullet.x - player.x
                local dy = bullet.y - player.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance > 600 then
                    table.remove(self.enemyBullets, i)
                end
            else
                table.remove(self.enemyBullets, i)
            end
        else
            table.remove(self.enemyBullets, i)
        end
    end
end

function BulletManager:draw()
    -- Draw player bullets
    for _, bullet in ipairs(self.playerBullets) do
        if bullet.active then
            love.graphics.setColor(0, 1, 1) -- Cyan
            love.graphics.circle('fill', bullet.x, bullet.y, bullet.radius)
            
            -- Add glow effect
            love.graphics.setColor(0, 1, 1, 0.3)
            love.graphics.circle('fill', bullet.x, bullet.y, bullet.radius * 2)
        end
    end
    
    -- Draw enemy bullets
    for _, bullet in ipairs(self.enemyBullets) do
        if bullet.active then
            love.graphics.setColor(1, 0.3, 0) -- Red-orange
            love.graphics.circle('fill', bullet.x, bullet.y, bullet.radius)
            
            -- Add glow effect
            love.graphics.setColor(1, 0.3, 0, 0.3)
            love.graphics.circle('fill', bullet.x, bullet.y, bullet.radius * 2)
        end
    end
    
    love.graphics.setColor(1, 1, 1)
end

return BulletManager
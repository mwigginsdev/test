-- Bomber Class - Slow, heavy damage ship with EMP blast ability

local ShipClass = require('src.ship_class')

local Bomber = {}
Bomber.__index = Bomber
setmetatable(Bomber, {__index = ShipClass})

function Bomber:new()
    local bomber = setmetatable({}, Bomber)
    bomber.type = "bomber"
    bomber:loadClassConfig()
    return bomber
end

function Bomber:loadClassConfig()
    self.name = "Bomber"
    self.description = "Heavy assault ship with explosive weapons and EMP capabilities"
    
    -- Slow but powerful
    self.baseStats = {
        health = 180,
        maxHealth = 180,
        mana = 50,
        maxMana = 50,
        attack = 35,
        defense = 12,
        speed = 240,
        fireRate = 0.25, -- Slow fire rate
        dexterity = 6,
        vitality = 20,
        wisdom = 8
    }
    
    self.statCaps = {
        health = 350,
        mana = 100,
        attack = 80,
        defense = 40,
        speed = 350,
        dexterity = 50,
        vitality = 60,
        wisdom = 25
    }
    
    -- Heavy weapons only
    self.canEquip = {
        weapons = {"missile", "explosive", "heavy", "plasma"},
        armor = {"medium", "heavy"},
        abilities = {"explosive", "area"}
    }
    
    -- Visual appearance
    self.shipShape = "pentagon"
    self.shipColor = {0.8, 0.6, 0.2} -- Orange/yellow
    self.shipSize = 1.2 -- Larger ship
    
    -- Bomber abilities
    self.abilities = {
        {
            name = "EMP Blast",
            description = "Disable enemy weapons in 150 unit radius for 3 seconds",
            manaCost = 45,
            cooldown = 30,
            use = function(player, class)
                return class:useEMPBlast(player)
            end
        }
    }
end

function Bomber:useEMPBlast(player)
    if not player then return false end
    
    -- Create EMP blast effect
    player.empBlast = {
        active = true,
        x = player.x,
        y = player.y,
        radius = 150,
        duration = 0.5, -- Visual effect duration
        startTime = love.timer.getTime()
    }
    
    -- Apply EMP effect to nearby entities (would be implemented in game logic)
    print("Bomber: EMP Blast activated!")
    return true
end

function Bomber:applyClassModifiers(stats)
    -- Bomber gets major damage bonus, speed penalty
    stats.attack = stats.attack * 1.4
    stats.speed = stats.speed * 0.8
    stats.defense = stats.defense * 1.2
    stats.fireRate = stats.fireRate * 1.3 -- Slower fire rate
    
    return stats
end

function Bomber:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update EMP blast visual effect
    if player.empBlast and player.empBlast.active then
        local elapsed = love.timer.getTime() - player.empBlast.startTime
        
        if elapsed >= player.empBlast.duration then
            player.empBlast.active = false
        else
            -- Expand blast radius over time
            player.empBlast.currentRadius = (elapsed / player.empBlast.duration) * player.empBlast.radius
        end
    end
end

-- Override bullet creation for area damage
function Bomber:createBullet(player, angle, bulletManager)
    if not bulletManager or not bulletManager.addPlayerBullet then
        return false
    end
    
    -- Create explosive bullet with area damage
    local bullet = bulletManager:addPlayerBullet(player.x, player.y, angle, 400, 35)
    
    if bullet then
        bullet.explosive = true
        bullet.explosionRadius = 40
        bullet.explosionDamage = 20
    end
    
    return true
end

function Bomber:drawClassEffects(player)
    if not player then return end
    
    -- Draw EMP blast effect
    if player.empBlast and player.empBlast.active then
        local elapsed = love.timer.getTime() - player.empBlast.startTime
        local progress = elapsed / player.empBlast.duration
        local currentRadius = progress * player.empBlast.radius
        
        -- EMP wave effect
        local alpha = 1 - progress
        love.graphics.setColor(0, 0.8, 1, alpha * 0.5)
        love.graphics.circle('line', player.empBlast.x, player.empBlast.y, currentRadius)
        love.graphics.circle('line', player.empBlast.x, player.empBlast.y, currentRadius * 0.8)
        
        -- Electric sparks
        for i = 1, 8 do
            local sparkAngle = (i / 8) * 2 * math.pi + elapsed * 4
            local sparkRadius = currentRadius * 0.9
            local sparkX = player.empBlast.x + math.cos(sparkAngle) * sparkRadius
            local sparkY = player.empBlast.y + math.sin(sparkAngle) * sparkRadius
            
            love.graphics.setColor(1, 1, 0, alpha)
            love.graphics.circle('fill', sparkX, sparkY, 3)
        end
    end
    
    -- Draw heavy armor indicator
    love.graphics.setColor(0.8, 0.6, 0.2, 0.3)
    love.graphics.circle('line', player.x, player.y, player.radius + 8)
    love.graphics.circle('line', player.x, player.y, player.radius + 12)
end

return Bomber
-- Interceptor Class - Fast, fragile ship with speed boost ability

local ShipClass = require('src.ship_class')

local Interceptor = {}
Interceptor.__index = Interceptor
setmetatable(Interceptor, {__index = ShipClass})

function Interceptor:new()
    local interceptor = setmetatable({}, Interceptor)
    interceptor.type = "interceptor"
    interceptor:loadClassConfig()
    return interceptor
end

function Interceptor:loadClassConfig()
    self.name = "Interceptor"
    self.description = "Fast and agile ship with speed boost and evasion abilities"
    
    -- Fast but fragile
    self.baseStats = {
        health = 80,
        maxHealth = 80,
        mana = 70,
        maxMana = 70,
        attack = 20,
        defense = 3,
        speed = 420,
        fireRate = 0.08, -- Very fast fire rate
        dexterity = 20,
        vitality = 8,
        wisdom = 15
    }
    
    self.statCaps = {
        health = 180,
        mana = 140,
        attack = 45,
        defense = 15,
        speed = 600,
        dexterity = 85,
        vitality = 30,
        wisdom = 45
    }
    
    -- Limited to rapid-fire weapons
    self.canEquip = {
        weapons = {"laser", "rapid", "burst"},
        armor = {"light"},
        abilities = {"mobility", "evasion"}
    }
    
    -- Visual appearance
    self.shipShape = "arrow"
    self.shipColor = {0.2, 0.8, 0.2} -- Green
    self.shipSize = 0.8 -- Smaller ship
    
    -- Interceptor abilities
    self.abilities = {
        {
            name = "Speed Boost",
            description = "Increase speed by 80% for 6 seconds",
            manaCost = 30,
            cooldown = 20,
            use = function(player, class)
                return class:useSpeedBoost(player)
            end
        }
    }
end

function Interceptor:useSpeedBoost(player)
    if not player then return false end
    
    -- Apply speed boost effect
    player.speedBoost = {
        active = true,
        duration = 6.0,
        speedMultiplier = 1.8,
        startTime = love.timer.getTime(),
        originalSpeed = player.speed
    }
    
    -- Apply speed boost immediately
    player.speed = player.speed * player.speedBoost.speedMultiplier
    
    print("Interceptor: Speed Boost activated!")
    return true
end

function Interceptor:applyClassModifiers(stats)
    -- Interceptor gets major speed bonus, minor damage penalty
    stats.speed = stats.speed * 1.3
    stats.attack = stats.attack * 0.9
    stats.fireRate = stats.fireRate * 0.8 -- Even faster fire rate
    
    return stats
end

function Interceptor:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update speed boost
    if player.speedBoost and player.speedBoost.active then
        local elapsed = love.timer.getTime() - player.speedBoost.startTime
        
        if elapsed >= player.speedBoost.duration then
            -- Remove speed boost
            player.speed = player.speedBoost.originalSpeed
            player.speedBoost.active = false
            print("Interceptor: Speed Boost ended")
        end
    end
    
    -- Passive evasion chance based on speed
    player.evasionChance = math.min(0.15, player.speed / 3000) -- Up to 15% evasion
end

-- Check if interceptor dodges an attack
function Interceptor:checkDodge(player)
    if not player or not player.evasionChance then return false end
    
    return math.random() < player.evasionChance
end

function Interceptor:drawClassEffects(player)
    if not player then return end
    
    -- Draw speed boost effect
    if player.speedBoost and player.speedBoost.active then
        local elapsed = love.timer.getTime() - player.speedBoost.startTime
        local remaining = player.speedBoost.duration - elapsed
        
        -- Speed trail effect
        local alpha = 0.4 + 0.2 * math.sin(love.timer.getTime() * 12)
        love.graphics.setColor(0, 1, 0, alpha)
        
        -- Draw speed lines behind ship
        for i = 1, 3 do
            local offsetX = math.cos(player.rotation + math.pi) * (player.radius + i * 8)
            local offsetY = math.sin(player.rotation + math.pi) * (player.radius + i * 8)
            love.graphics.line(
                player.x + offsetX - 3, player.y + offsetY - 3,
                player.x + offsetX + 3, player.y + offsetY + 3
            )
            love.graphics.line(
                player.x + offsetX + 3, player.y + offsetY - 3,
                player.x + offsetX - 3, player.y + offsetY + 3
            )
        end
        
        -- Time remaining display
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.print("BOOST: " .. string.format("%.1f", remaining), 
                          player.x - 30, player.y - 40)
    end
    
    -- Draw evasion indicator
    if player.evasionChance and player.evasionChance > 0 then
        love.graphics.setColor(0, 1, 1, 0.3)
        love.graphics.circle('line', player.x, player.y, player.radius + 5)
    end
end

return Interceptor
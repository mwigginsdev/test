-- Tank Class - High survivability with taunt and damage mitigation

local ShipClass = require('src.ship_class')

local Tank = {}
Tank.__index = Tank
setmetatable(Tank, {__index = ShipClass})

function Tank:new()
    local tank = setmetatable({}, Tank)
    tank.type = "tank"
    tank:loadClassConfig()
    return tank
end

function Tank:loadClassConfig()
    self.name = "Tank"
    self.description = "Heavy defensive ship with high survivability and taunt abilities"
    
    -- High health, low damage
    self.baseStats = {
        health = 200,
        maxHealth = 200,
        mana = 40,
        maxMana = 40,
        attack = 15,
        defense = 18,
        speed = 220,
        fireRate = 0.3, -- Very slow fire rate
        dexterity = 5,
        vitality = 25,
        wisdom = 6
    }
    
    self.statCaps = {
        health = 400,
        mana = 80,
        attack = 35,
        defense = 50,
        speed = 320,
        dexterity = 40,
        vitality = 70,
        wisdom = 20
    }
    
    -- Heavy equipment only
    self.canEquip = {
        weapons = {"heavy", "shield_cannon", "defensive"},
        armor = {"heavy", "ultra_heavy"},
        abilities = {"defensive", "taunt"}
    }
    
    -- Visual appearance
    self.shipShape = "pentagon"
    self.shipColor = {0.6, 0.6, 0.6} -- Gray/silver
    self.shipSize = 1.3 -- Large ship
    
    -- Tank abilities
    self.abilities = {
        {
            name = "Taunt",
            description = "Force all nearby enemies to target you for 6 seconds",
            manaCost = 35,
            cooldown = 20,
            use = function(player, class)
                return class:useTaunt(player)
            end
        }
    }
end

function Tank:useTaunt(player)
    if not player then return false end
    
    -- Apply taunt effect
    player.taunt = {
        active = true,
        duration = 6.0,
        range = 200,
        startTime = love.timer.getTime()
    }
    
    print("Tank: Taunt activated!")
    return true
end

function Tank:applyClassModifiers(stats)
    -- Tank gets major health and defense bonus, damage and speed penalty
    stats.health = stats.health * 1.6
    stats.maxHealth = stats.maxHealth * 1.6
    stats.defense = stats.defense * 1.8
    stats.attack = stats.attack * 0.7
    stats.speed = stats.speed * 0.75
    stats.fireRate = stats.fireRate * 1.4 -- Slower fire rate
    
    return stats
end

function Tank:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update taunt
    if player.taunt and player.taunt.active then
        local elapsed = love.timer.getTime() - player.taunt.startTime
        
        if elapsed >= player.taunt.duration then
            player.taunt.active = false
            print("Tank: Taunt ended")
        end
    end
    
    -- Passive damage reduction
    player.damageReduction = 0.15 -- 15% damage reduction
end

-- Check if tank is taunting enemies
function Tank:isTaunting(player)
    return player and player.taunt and player.taunt.active
end

-- Get taunt range
function Tank:getTauntRange(player)
    if not self:isTaunting(player) then return 0 end
    return player.taunt.range
end

-- Apply damage reduction
function Tank:modifyIncomingDamage(player, damage)
    if not player then return damage end
    
    local reduction = player.damageReduction or 0
    return damage * (1 - reduction)
end

function Tank:drawClassEffects(player)
    if not player then return end
    
    -- Draw taunt effect
    if player.taunt and player.taunt.active then
        local elapsed = love.timer.getTime() - player.taunt.startTime
        local remaining = player.taunt.duration - elapsed
        
        -- Taunt aura effect
        local alpha = 0.4 + 0.3 * math.sin(love.timer.getTime() * 5)
        love.graphics.setColor(1, 0.3, 0.3, alpha)
        love.graphics.circle('line', player.x, player.y, player.taunt.range)
        love.graphics.circle('line', player.x, player.y, player.taunt.range * 0.8)
        
        -- Aggro lines pointing inward
        for i = 1, 8 do
            local angle = (i / 8) * 2 * math.pi + elapsed * 2
            local innerRadius = player.radius + 10
            local outerRadius = player.taunt.range * 0.6
            
            local innerX = player.x + math.cos(angle) * innerRadius
            local innerY = player.y + math.sin(angle) * innerRadius
            local outerX = player.x + math.cos(angle) * outerRadius
            local outerY = player.y + math.sin(angle) * outerRadius
            
            love.graphics.setColor(1, 0.5, 0.5, alpha)
            love.graphics.line(outerX, outerY, innerX, innerY)
        end
        
        -- Time remaining display
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print("TAUNT: " .. string.format("%.1f", remaining), 
                          player.x - 30, player.y - 40)
    end
    
    -- Draw armor plating indicator
    love.graphics.setColor(0.6, 0.6, 0.6, 0.4)
    love.graphics.circle('line', player.x, player.y, player.radius + 8)
    love.graphics.circle('line', player.x, player.y, player.radius + 12)
    love.graphics.circle('line', player.x, player.y, player.radius + 16)
    
    -- Draw damage reduction indicator
    if player.damageReduction and player.damageReduction > 0 then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
        love.graphics.circle('fill', player.x, player.y, player.radius + 5)
    end
end

return Tank
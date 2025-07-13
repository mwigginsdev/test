-- Stealth Class - Invisibility and backstab damage bonuses

local ShipClass = require('src.ship_class')

local Stealth = {}
Stealth.__index = Stealth
setmetatable(Stealth, {__index = ShipClass})

function Stealth:new()
    local stealth = setmetatable({}, Stealth)
    stealth.type = "stealth"
    stealth:loadClassConfig()
    return stealth
end

function Stealth:loadClassConfig()
    self.name = "Stealth"
    self.description = "Invisible assassin with cloaking and backstab abilities"
    
    -- Balanced with focus on stealth
    self.baseStats = {
        health = 90,
        maxHealth = 90,
        mana = 80,
        maxMana = 80,
        attack = 22,
        defense = 4,
        speed = 350,
        fireRate = 0.14,
        dexterity = 18,
        vitality = 10,
        wisdom = 16
    }
    
    self.statCaps = {
        health = 200,
        mana = 160,
        attack = 55,
        defense = 20,
        speed = 520,
        dexterity = 80,
        vitality = 35,
        wisdom = 50
    }
    
    -- Stealth weapons
    self.canEquip = {
        weapons = {"laser", "stealth", "blade", "poison"},
        armor = {"light"},
        abilities = {"stealth", "assassination"}
    }
    
    -- Visual appearance
    self.shipShape = "diamond"
    self.shipColor = {0.4, 0.2, 0.8} -- Purple
    self.shipSize = 0.85
    
    -- Stealth abilities
    self.abilities = {
        {
            name = "Cloak",
            description = "Become invisible for 8 seconds, +50% damage from behind",
            manaCost = 60,
            cooldown = 35,
            use = function(player, class)
                return class:useCloak(player)
            end
        }
    }
end

function Stealth:useCloak(player)
    if not player then return false end
    
    -- Apply cloak effect
    player.cloak = {
        active = true,
        duration = 8.0,
        backstabMultiplier = 1.5,
        startTime = love.timer.getTime()
    }
    
    print("Stealth: Cloak activated!")
    return true
end

function Stealth:applyClassModifiers(stats)
    -- Stealth gets speed and dexterity bonus, health penalty
    stats.speed = stats.speed * 1.15
    stats.dexterity = stats.dexterity * 1.2
    stats.health = stats.health * 0.9
    
    return stats
end

function Stealth:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update cloak
    if player.cloak and player.cloak.active then
        local elapsed = love.timer.getTime() - player.cloak.startTime
        
        if elapsed >= player.cloak.duration then
            player.cloak.active = false
            print("Stealth: Cloak ended")
        end
    end
end

-- Check if stealth gets backstab bonus
function Stealth:getBackstabMultiplier(player, target)
    if not player or not player.cloak or not player.cloak.active then
        return 1.0
    end
    
    if not target then return player.cloak.backstabMultiplier end
    
    -- Calculate if attacking from behind
    local dx = target.x - player.x
    local dy = target.y - player.y
    local attackAngle = math.atan2(dy, dx)
    
    -- Target's facing direction (assuming they have rotation)
    local targetFacing = target.rotation or 0
    local angleDiff = math.abs(attackAngle - targetFacing)
    
    -- Normalize angle difference to 0-π
    if angleDiff > math.pi then
        angleDiff = 2 * math.pi - angleDiff
    end
    
    -- Backstab if attacking from behind (within 60 degrees)
    if angleDiff > math.pi - math.pi/3 then
        return player.cloak.backstabMultiplier
    end
    
    return 1.0
end

-- Override bullet damage for backstab
function Stealth:modifyBulletDamage(player, baseDamage, target)
    local multiplier = self:getBackstabMultiplier(player, target)
    return baseDamage * multiplier
end

function Stealth:drawClassEffects(player)
    if not player then return end
    
    -- Draw cloak effect
    if player.cloak and player.cloak.active then
        local elapsed = love.timer.getTime() - player.cloak.startTime
        local remaining = player.cloak.duration - elapsed
        
        -- Shimmer effect for cloaked ship
        local alpha = 0.3 + 0.2 * math.sin(love.timer.getTime() * 10)
        
        -- Draw partially transparent ship overlay
        love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(player.rotation)
        
        love.graphics.setColor(0.4, 0.2, 0.8, alpha)
        player:drawShipShape()
        
        -- Shimmer lines
        for i = 1, 4 do
            local lineAlpha = alpha * 0.5
            love.graphics.setColor(0.8, 0.4, 1, lineAlpha)
            local offset = i * 5
            love.graphics.line(-player.radius - offset, -offset, player.radius + offset, offset)
            love.graphics.line(-player.radius - offset, offset, player.radius + offset, -offset)
        end
        
        love.graphics.pop()
        
        -- Time remaining display
        love.graphics.setColor(0.8, 0.4, 1)
        love.graphics.print("CLOAKED: " .. string.format("%.1f", remaining), 
                          player.x - 35, player.y - 40)
    end
    
    -- Draw stealth indicator when not cloaked
    if not (player.cloak and player.cloak.active) then
        love.graphics.setColor(0.4, 0.2, 0.8, 0.2)
        love.graphics.circle('line', player.x, player.y, player.radius + 3)
    end
end

-- Check if stealth ship should be visible to enemies
function Stealth:isVisibleToEnemies(player)
    if not player or not player.cloak then return true end
    return not player.cloak.active
end

-- Reduce visibility when cloaked
function Stealth:getVisibilityAlpha(player)
    if player and player.cloak and player.cloak.active then
        return 0.3 -- Semi-transparent when cloaked
    end
    return 1.0
end

return Stealth
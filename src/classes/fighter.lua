-- Fighter Class - Balanced fighter with weapon overcharge ability

local ShipClass = require('src.ship_class')

local Fighter = {}
Fighter.__index = Fighter
setmetatable(Fighter, {__index = ShipClass})

function Fighter:new()
    local fighter = setmetatable({}, Fighter)
    fighter.type = "fighter"
    fighter:loadClassConfig()
    return fighter
end

function Fighter:loadClassConfig()
    self.name = "Fighter"
    self.description = "Balanced ship with good all-around capabilities and weapon overcharge"
    
    -- Balanced stats
    self.baseStats = {
        health = 130,
        maxHealth = 130,
        mana = 60,
        maxMana = 60,
        attack = 25,
        defense = 8,
        speed = 320,
        fireRate = 0.12,
        dexterity = 12,
        vitality = 15,
        wisdom = 12
    }
    
    self.statCaps = {
        health = 250,
        mana = 120,
        attack = 60,
        defense = 30,
        speed = 450,
        dexterity = 70,
        vitality = 50,
        wisdom = 35
    }
    
    -- Can use most equipment
    self.canEquip = {
        weapons = {"laser", "plasma", "missile", "beam"},
        armor = {"light", "medium"},
        abilities = {"combat", "utility"}
    }
    
    -- Visual appearance
    self.shipShape = "triangle"
    self.shipColor = {0.8, 0.2, 0.2} -- Red
    self.shipSize = 1.0
    
    -- Fighter abilities
    self.abilities = {
        {
            name = "Weapon Overcharge",
            description = "Increase weapon damage by 100% for 8 seconds",
            manaCost = 40,
            cooldown = 25,
            use = function(player, class)
                return class:useWeaponOvercharge(player)
            end
        }
    }
end

function Fighter:useWeaponOvercharge(player)
    if not player then return false end
    
    -- Apply weapon overcharge effect
    player.weaponOvercharge = {
        active = true,
        duration = 8.0,
        damageMultiplier = 2.0,
        startTime = love.timer.getTime()
    }
    
    print("Fighter: Weapon Overcharge activated!")
    return true
end

function Fighter:applyClassModifiers(stats)
    -- Fighter gets small bonus to attack and fire rate
    stats.attack = stats.attack * 1.1
    stats.fireRate = stats.fireRate * 0.95 -- Faster fire rate (lower number = faster)
    
    return stats
end

function Fighter:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update weapon overcharge
    if player.weaponOvercharge and player.weaponOvercharge.active then
        local elapsed = love.timer.getTime() - player.weaponOvercharge.startTime
        
        if elapsed >= player.weaponOvercharge.duration then
            player.weaponOvercharge.active = false
            print("Fighter: Weapon Overcharge ended")
        end
    end
end

-- Override shooting to apply overcharge
function Fighter:modifyBulletDamage(player, baseDamage)
    if player.weaponOvercharge and player.weaponOvercharge.active then
        return baseDamage * player.weaponOvercharge.damageMultiplier
    end
    return baseDamage
end

function Fighter:drawClassEffects(player)
    if not player then return end
    
    -- Draw overcharge effect
    if player.weaponOvercharge and player.weaponOvercharge.active then
        local elapsed = love.timer.getTime() - player.weaponOvercharge.startTime
        local remaining = player.weaponOvercharge.duration - elapsed
        
        -- Pulsing red effect around ship
        local alpha = 0.3 + 0.3 * math.sin(love.timer.getTime() * 8)
        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.circle('line', player.x, player.y, player.radius + 10)
        love.graphics.circle('line', player.x, player.y, player.radius + 15)
        
        -- Time remaining display
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.print("OVERCHARGE: " .. string.format("%.1f", remaining), 
                          player.x - 40, player.y - 40)
    end
end

return Fighter
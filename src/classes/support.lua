-- Support Class - Healing and buff abilities for team support

local ShipClass = require('src.ship_class')

local Support = {}
Support.__index = Support
setmetatable(Support, {__index = ShipClass})

function Support:new()
    local support = setmetatable({}, Support)
    support.type = "support"
    support:loadClassConfig()
    return support
end

function Support:loadClassConfig()
    self.name = "Support"
    self.description = "Team support ship with healing and shield boost abilities"
    
    -- Balanced with focus on utility
    self.baseStats = {
        health = 110,
        maxHealth = 110,
        mana = 90,
        maxMana = 90,
        attack = 18,
        defense = 10,
        speed = 310,
        fireRate = 0.18,
        dexterity = 10,
        vitality = 12,
        wisdom = 20 -- High wisdom for mana regen
    }
    
    self.statCaps = {
        health = 220,
        mana = 180,
        attack = 40,
        defense = 35,
        speed = 420,
        dexterity = 60,
        vitality = 40,
        wisdom = 60
    }
    
    -- Support equipment
    self.canEquip = {
        weapons = {"laser", "beam", "utility"},
        armor = {"light", "medium"},
        abilities = {"healing", "support", "utility"}
    }
    
    -- Visual appearance
    self.shipShape = "diamond"
    self.shipColor = {0.2, 0.8, 0.8} -- Cyan
    self.shipSize = 0.9
    
    -- Support abilities
    self.abilities = {
        {
            name = "Healing Beam",
            description = "Heal nearby allies for 60 HP over 3 seconds",
            manaCost = 50,
            cooldown = 15,
            use = function(player, class)
                return class:useHealingBeam(player)
            end
        },
        {
            name = "Shield Boost",
            description = "Grant 30% damage reduction to nearby allies for 10 seconds",
            manaCost = 35,
            cooldown = 25,
            use = function(player, class)
                return class:useShieldBoost(player)
            end
        }
    }
end

function Support:useHealingBeam(player)
    if not player then return false end
    
    -- Create healing beam effect
    player.healingBeam = {
        active = true,
        duration = 3.0,
        healRate = 20, -- HP per second
        range = 120,
        startTime = love.timer.getTime()
    }
    
    print("Support: Healing Beam activated!")
    return true
end

function Support:useShieldBoost(player)
    if not player then return false end
    
    -- Create shield boost effect
    player.shieldBoost = {
        active = true,
        duration = 10.0,
        damageReduction = 0.3,
        range = 100,
        startTime = love.timer.getTime()
    }
    
    print("Support: Shield Boost activated!")
    return true
end

function Support:applyClassModifiers(stats)
    -- Support gets mana regen bonus, damage penalty
    stats.attack = stats.attack * 0.8
    stats.wisdom = stats.wisdom * 1.5 -- Better mana regen
    stats.defense = stats.defense * 1.1
    
    return stats
end

function Support:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update healing beam
    if player.healingBeam and player.healingBeam.active then
        local elapsed = love.timer.getTime() - player.healingBeam.startTime
        
        if elapsed >= player.healingBeam.duration then
            player.healingBeam.active = false
            print("Support: Healing Beam ended")
        else
            -- Apply healing to nearby allies (would need player manager integration)
            -- For now, just heal self as demonstration
            if elapsed % 1.0 < dt then -- Heal every second
                player.health = math.min(player.maxHealth, player.health + player.healingBeam.healRate)
            end
        end
    end
    
    -- Update shield boost
    if player.shieldBoost and player.shieldBoost.active then
        local elapsed = love.timer.getTime() - player.shieldBoost.startTime
        
        if elapsed >= player.shieldBoost.duration then
            player.shieldBoost.active = false
            print("Support: Shield Boost ended")
        end
    end
end

-- Check if support provides damage reduction
function Support:getDamageReduction(player, targetPlayer)
    if not player or not player.shieldBoost or not player.shieldBoost.active then
        return 0
    end
    
    if not targetPlayer then return 0 end
    
    -- Check if target is in range
    local dx = player.x - targetPlayer.x
    local dy = player.y - targetPlayer.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance <= player.shieldBoost.range then
        return player.shieldBoost.damageReduction
    end
    
    return 0
end

function Support:drawClassEffects(player)
    if not player then return end
    
    -- Draw healing beam effect
    if player.healingBeam and player.healingBeam.active then
        local elapsed = love.timer.getTime() - player.healingBeam.startTime
        local remaining = player.healingBeam.duration - elapsed
        
        -- Healing aura
        local alpha = 0.3 + 0.2 * math.sin(love.timer.getTime() * 6)
        love.graphics.setColor(0, 1, 0, alpha)
        love.graphics.circle('line', player.x, player.y, player.healingBeam.range)
        
        -- Healing particles
        for i = 1, 6 do
            local angle = (i / 6) * 2 * math.pi + elapsed * 2
            local radius = player.healingBeam.range * 0.7
            local particleX = player.x + math.cos(angle) * radius
            local particleY = player.y + math.sin(angle) * radius
            
            love.graphics.setColor(0, 1, 0.5, alpha)
            love.graphics.circle('fill', particleX, particleY, 4)
        end
        
        -- Time remaining display
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.print("HEALING: " .. string.format("%.1f", remaining), 
                          player.x - 35, player.y - 40)
    end
    
    -- Draw shield boost effect
    if player.shieldBoost and player.shieldBoost.active then
        local elapsed = love.timer.getTime() - player.shieldBoost.startTime
        local remaining = player.shieldBoost.duration - elapsed
        
        -- Shield aura
        local alpha = 0.4 + 0.3 * math.sin(love.timer.getTime() * 4)
        love.graphics.setColor(0, 0.5, 1, alpha)
        love.graphics.circle('line', player.x, player.y, player.shieldBoost.range)
        love.graphics.circle('line', player.x, player.y, player.shieldBoost.range * 0.8)
        
        -- Time remaining display
        love.graphics.setColor(0.5, 0.5, 1)
        love.graphics.print("SHIELD: " .. string.format("%.1f", remaining), 
                          player.x - 30, player.y - 55)
    end
    
    -- Draw support range indicator
    love.graphics.setColor(0.2, 0.8, 0.8, 0.2)
    love.graphics.circle('line', player.x, player.y, 100) -- Standard support range
end

return Support
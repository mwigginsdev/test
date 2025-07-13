-- Defensive System - Handles dodge chance, armor, and status resistance

local DefensiveSystem = {}
DefensiveSystem.__index = DefensiveSystem

function DefensiveSystem:new()
    local system = setmetatable({}, DefensiveSystem)
    
    -- Defensive stats tracking
    system.playerDefenses = {}
    
    -- Dodge chance configuration
    system.dodgeConfig = {
        baseChance = 0.0,
        speedThreshold = 300, -- Speed required for dodge chance
        maxDodgeChance = 0.2, -- 20% max dodge chance
        speedPerPercent = 50, -- Speed per 1% dodge chance above threshold
    }
    
    -- Armor configuration
    system.armorConfig = {
        flatReduction = true, -- Flat damage reduction vs percentage
        maxReduction = 0.8, -- Maximum 80% damage reduction
    }
    
    return system
end

-- Initialize defensive stats for a player
function DefensiveSystem:initializePlayer(player)
    if not player or not player.id then return end
    
    self.playerDefenses[player.id] = {
        armor = 0,
        dodgeChance = 0,
        statusResistance = {
            paralyzed = 0,
            slowed = 0,
            weakness = 0,
            armorBreak = 0,
            bleeding = 0,
            confused = 0,
            blind = 0
        },
        lastDodgeTime = 0,
        totalDodges = 0
    }
    
    self:updatePlayerDefenses(player)
end

-- Update player's defensive stats based on equipment and speed
function DefensiveSystem:updatePlayerDefenses(player)
    if not player or not player.id then return end
    if not self.playerDefenses[player.id] then
        self:initializePlayer(player)
        return
    end
    
    local defenses = self.playerDefenses[player.id]
    
    -- Calculate dodge chance based on speed
    local speed = player.speed or 300
    local dodgeChance = 0
    
    if speed > self.dodgeConfig.speedThreshold then
        local excessSpeed = speed - self.dodgeConfig.speedThreshold
        dodgeChance = math.min(
            self.dodgeConfig.maxDodgeChance,
            excessSpeed / self.dodgeConfig.speedPerPercent / 100
        )
    end
    
    defenses.dodgeChance = dodgeChance
    
    -- Calculate armor from equipment
    local armor = 0
    if player.shield and player.shield.stats then
        armor = armor + (player.shield.stats.armor or 0)
    end
    
    -- Add class-based armor bonuses
    if player.shipClass then
        armor = armor + (player.shipClass.baseStats.defense or 0)
    end
    
    defenses.armor = armor
    
    -- Calculate status resistances from equipment
    -- This would be expanded when we have equipment with resistance stats
    for effectType, _ in pairs(defenses.statusResistance) do
        local resistance = 0
        
        -- Example: Heavy armor provides some status resistance
        if armor > 15 then
            resistance = resistance + 0.1 -- 10% resistance
        end
        
        if armor > 25 then
            resistance = resistance + 0.1 -- 20% total resistance
        end
        
        -- Class-specific resistances
        if player.shipClass then
            if player.shipClass.type == "tank" then
                resistance = resistance + 0.15 -- Tanks get 15% more resistance
            elseif player.shipClass.type == "support" then
                resistance = resistance + 0.1 -- Support gets 10% more resistance
            end
        end
        
        defenses.statusResistance[effectType] = math.min(0.5, resistance) -- Cap at 50%
    end
end

-- Attempt to dodge an attack
function DefensiveSystem:attemptDodge(player)
    if not player or not player.id then return false end
    if not self.playerDefenses[player.id] then return false end
    
    local defenses = self.playerDefenses[player.id]
    local currentTime = love.timer.getTime()
    
    -- Apply dodge cooldown to prevent spam dodging
    if currentTime - defenses.lastDodgeTime < 0.1 then
        return false
    end
    
    if math.random() < defenses.dodgeChance then
        defenses.lastDodgeTime = currentTime
        defenses.totalDodges = defenses.totalDodges + 1
        
        -- Create dodge effect
        player.dodgeEffect = {
            startTime = currentTime,
            duration = 0.3
        }
        
        print("DODGE! (" .. string.format("%.1f", defenses.dodgeChance * 100) .. "% chance)")
        return true
    end
    
    return false
end

-- Calculate damage reduction from armor
function DefensiveSystem:calculateDamageReduction(player, incomingDamage)
    if not player or not player.id then return incomingDamage end
    if not self.playerDefenses[player.id] then return incomingDamage end
    
    local defenses = self.playerDefenses[player.id]
    local armor = defenses.armor
    
    if armor <= 0 then return incomingDamage end
    
    local reducedDamage = incomingDamage
    
    if self.armorConfig.flatReduction then
        -- Flat damage reduction
        reducedDamage = math.max(1, incomingDamage - armor)
    else
        -- Percentage damage reduction
        local reductionPercent = math.min(
            self.armorConfig.maxReduction,
            armor / (armor + 100) -- Diminishing returns formula
        )
        reducedDamage = incomingDamage * (1 - reductionPercent)
    end
    
    local blocked = incomingDamage - reducedDamage
    if blocked > 0 then
        -- Create armor block effect
        player.armorBlockEffect = {
            startTime = love.timer.getTime(),
            duration = 0.5,
            blockedDamage = blocked
        }
    end
    
    return reducedDamage
end

-- Check status effect resistance
function DefensiveSystem:checkStatusResistance(player, effectType, baseDuration)
    if not player or not player.id then return baseDuration end
    if not self.playerDefenses[player.id] then return baseDuration end
    
    local defenses = self.playerDefenses[player.id]
    local resistance = defenses.statusResistance[effectType] or 0
    
    if resistance <= 0 then return baseDuration end
    
    -- Resistance can reduce duration or provide chance to resist completely
    if math.random() < resistance * 0.3 then -- 30% of resistance = complete immunity chance
        print("Resisted " .. effectType .. "! (" .. string.format("%.1f", resistance * 30) .. "% chance)")
        return 0 -- Completely resisted
    else
        -- Reduce duration
        local reducedDuration = baseDuration * (1 - resistance * 0.5)
        if reducedDuration < baseDuration then
            print("Reduced " .. effectType .. " duration by " .. string.format("%.1f", (1 - reducedDuration/baseDuration) * 100) .. "%")
        end
        return reducedDuration
    end
end

-- Get defensive stats for display
function DefensiveSystem:getDefensiveStats(player)
    if not player or not player.id then return nil end
    if not self.playerDefenses[player.id] then return nil end
    
    local defenses = self.playerDefenses[player.id]
    
    return {
        armor = defenses.armor,
        dodgeChance = defenses.dodgeChance * 100, -- Convert to percentage
        totalDodges = defenses.totalDodges,
        statusResistances = defenses.statusResistance
    }
end

-- Draw defensive effects
function DefensiveSystem:drawDefensiveEffects(player)
    if not player then return end
    
    -- Draw dodge effect
    if player.dodgeEffect then
        local effect = player.dodgeEffect
        local elapsed = love.timer.getTime() - effect.startTime
        
        if elapsed < effect.duration then
            local alpha = 1.0 - (elapsed / effect.duration)
            
            -- Dodge shimmer effect
            love.graphics.setColor(1, 1, 0, alpha)
            love.graphics.circle('line', player.x, player.y, player.radius + 10)
            love.graphics.circle('line', player.x, player.y, player.radius + 15)
            
            -- Dodge text
            love.graphics.setColor(1, 1, 0, alpha)
            love.graphics.print("DODGE!", player.x - 25, player.y - 40, 0, 1.2, 1.2)
        else
            player.dodgeEffect = nil
        end
    end
    
    -- Draw armor block effect
    if player.armorBlockEffect then
        local effect = player.armorBlockEffect
        local elapsed = love.timer.getTime() - effect.startTime
        
        if elapsed < effect.duration then
            local alpha = 1.0 - (elapsed / effect.duration)
            
            -- Armor shield effect
            love.graphics.setColor(0.5, 0.5, 1, alpha * 0.6)
            love.graphics.circle('fill', player.x, player.y, player.radius + 8)
            love.graphics.setColor(0.8, 0.8, 1, alpha)
            love.graphics.circle('line', player.x, player.y, player.radius + 8)
            
            -- Block text
            love.graphics.setColor(0.5, 0.5, 1, alpha)
            love.graphics.print("-" .. math.floor(effect.blockedDamage), 
                              player.x + 20, player.y - 30, 0, 1, 1)
        else
            player.armorBlockEffect = nil
        end
    end
end

-- Draw defensive stats UI
function DefensiveSystem:drawDefensiveUI(player, x, y)
    if not player or not player.id then return end
    if not self.playerDefenses[player.id] then return end
    
    local defenses = self.playerDefenses[player.id]
    
    -- Armor display
    love.graphics.setColor(0.5, 0.5, 1)
    love.graphics.print("ARMOR: " .. defenses.armor, x, y, 0, 1, 1)
    
    -- Dodge chance display
    local dodgePercent = defenses.dodgeChance * 100
    if dodgePercent > 0 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("DODGE: " .. string.format("%.1f", dodgePercent) .. "%", x, y + 15, 0, 1, 1)
        
        if defenses.totalDodges > 0 then
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print("Total Dodges: " .. defenses.totalDodges, x, y + 30, 0, 0.8, 0.8)
        end
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("DODGE: 0% (need " .. self.dodgeConfig.speedThreshold .. "+ speed)", 
                          x, y + 15, 0, 0.8, 0.8)
    end
    
    -- Status resistance summary
    local hasResistance = false
    for effectType, resistance in pairs(defenses.statusResistance) do
        if resistance > 0 then
            hasResistance = true
            break
        end
    end
    
    if hasResistance then
        love.graphics.setColor(0, 1, 0.5)
        love.graphics.print("STATUS RESISTANCE:", x, y + 45, 0, 0.9, 0.9)
        
        local yOffset = 60
        for effectType, resistance in pairs(defenses.statusResistance) do
            if resistance > 0 then
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print(effectType:gsub("^%l", string.upper) .. ": " .. 
                                  string.format("%.0f", resistance * 100) .. "%", 
                                  x + 10, y + yOffset, 0, 0.7, 0.7)
                yOffset = yOffset + 12
            end
        end
    end
end

-- Apply all defensive calculations to incoming damage
function DefensiveSystem:processIncomingDamage(player, damage)
    if not player then return damage end
    
    -- Update defensive stats first
    self:updatePlayerDefenses(player)
    
    -- Check for dodge first
    if self:attemptDodge(player) then
        return 0 -- Completely avoided
    end
    
    -- Apply armor reduction
    local reducedDamage = self:calculateDamageReduction(player, damage)
    
    return reducedDamage
end

-- Clean up defensive data for a player
function DefensiveSystem:cleanupPlayer(playerId)
    if self.playerDefenses[playerId] then
        self.playerDefenses[playerId] = nil
    end
end

return DefensiveSystem
-- Mana/Energy Resource System

local ManaSystem = {}
ManaSystem.__index = ManaSystem

function ManaSystem:new()
    local system = setmetatable({}, ManaSystem)
    
    -- Default mana regeneration rates
    system.baseRegenRate = 10 -- Mana per second
    system.combatRegenPenalty = 0.5 -- Reduced regen in combat
    system.combatTimeout = 3.0 -- Seconds after damage before leaving combat
    
    return system
end

-- Initialize mana for a player
function ManaSystem:initializePlayer(player)
    if not player then return end
    
    -- Set up mana properties if not already present
    if not player.mana then
        player.mana = player.maxMana or 50
    end
    
    if not player.maxMana then
        player.maxMana = 50
    end
    
    -- Track combat state
    player.lastDamageTime = 0
    player.inCombat = false
    player.manaRegenRate = self.baseRegenRate
end

-- Update mana regeneration
function ManaSystem:updatePlayer(player, dt)
    if not player then return end
    
    -- Update combat state
    local timeSinceLastDamage = love.timer.getTime() - (player.lastDamageTime or 0)
    player.inCombat = timeSinceLastDamage < self.combatTimeout
    
    -- Calculate regeneration rate
    local regenRate = self.baseRegenRate
    if player.inCombat then
        regenRate = regenRate * self.combatRegenPenalty
    end
    
    -- Apply wisdom bonus (if available)
    if player.wisdom then
        local wisdomBonus = 1 + (player.wisdom / 100) -- 1% per wisdom point
        regenRate = regenRate * wisdomBonus
    end
    
    player.manaRegenRate = regenRate
    
    -- Regenerate mana
    if player.mana < player.maxMana then
        player.mana = math.min(player.maxMana, player.mana + regenRate * dt)
    end
end

-- Consume mana
function ManaSystem:consumeMana(player, amount)
    if not player or not player.mana then return false end
    
    if player.mana >= amount then
        player.mana = player.mana - amount
        return true
    end
    
    return false
end

-- Check if player has enough mana
function ManaSystem:hasMana(player, amount)
    if not player or not player.mana then return false end
    return player.mana >= amount
end

-- Get mana percentage
function ManaSystem:getManaPercentage(player)
    if not player or not player.mana or not player.maxMana then return 0 end
    if player.maxMana == 0 then return 1 end
    
    return player.mana / player.maxMana
end

-- Mark player as taking damage (affects regen)
function ManaSystem:markDamaged(player)
    if not player then return end
    player.lastDamageTime = love.timer.getTime()
end

-- Draw mana bar
function ManaSystem:drawManaBar(player, x, y, width, height)
    if not player or not player.mana then return end
    
    width = width or 100
    height = height or 8
    
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle('fill', x, y, width, height)
    
    -- Mana fill
    local manaPercent = self:getManaPercentage(player)
    local manaWidth = width * manaPercent
    
    -- Color based on mana level
    if manaPercent > 0.6 then
        love.graphics.setColor(0.2, 0.4, 1.0, 0.9) -- Blue
    elseif manaPercent > 0.3 then
        love.graphics.setColor(0.8, 0.8, 0.2, 0.9) -- Yellow
    else
        love.graphics.setColor(0.8, 0.2, 0.2, 0.9) -- Red
    end
    
    love.graphics.rectangle('fill', x, y, manaWidth, height)
    
    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle('line', x, y, width, height)
    
    -- Mana text
    love.graphics.setColor(1, 1, 1)
    local manaText = string.format("%d/%d", math.floor(player.mana), math.floor(player.maxMana))
    love.graphics.print(manaText, x + width + 5, y - 2, 0, 0.8, 0.8)
    
    -- Regeneration indicator
    if player.manaRegenRate and player.manaRegenRate > 0 then
        local regenText = string.format("+%.1f/s", player.manaRegenRate)
        love.graphics.setColor(0.4, 0.8, 1.0, 0.7)
        love.graphics.print(regenText, x + width + 5, y + height + 2, 0, 0.7, 0.7)
    end
    
    -- Combat indicator
    if player.inCombat then
        love.graphics.setColor(1, 0.3, 0.3, 0.8)
        love.graphics.print("COMBAT", x - 50, y - 2, 0, 0.7, 0.7)
    end
end

-- Apply mana-based effects
function ManaSystem:getManaEffectMultiplier(player, effectType)
    if not player or not player.mana or not player.maxMana then return 1.0 end
    
    local manaPercent = self:getManaPercentage(player)
    
    -- Different effects based on type
    if effectType == "damage" then
        -- Higher mana = more damage (up to 20% bonus)
        return 1.0 + (manaPercent * 0.2)
    elseif effectType == "speed" then
        -- Lower mana = slower movement (down to 80% speed)
        return 0.8 + (manaPercent * 0.2)
    elseif effectType == "cooldown" then
        -- Higher mana = faster cooldowns (up to 15% faster)
        return 1.0 - (manaPercent * 0.15)
    end
    
    return 1.0
end

-- Set custom mana regeneration rate
function ManaSystem:setRegenRate(player, rate)
    if not player then return end
    player.customManaRegen = rate
end

-- Get effective mana regen (including class bonuses)
function ManaSystem:getEffectiveRegenRate(player)
    if not player then return 0 end
    
    local baseRate = player.customManaRegen or self.baseRegenRate
    
    -- Combat penalty
    if player.inCombat then
        baseRate = baseRate * self.combatRegenPenalty
    end
    
    -- Wisdom bonus
    if player.wisdom then
        local wisdomBonus = 1 + (player.wisdom / 100)
        baseRate = baseRate * wisdomBonus
    end
    
    -- Class-specific bonuses could be applied here
    if player.shipClass and player.shipClass.type == "psychic" then
        baseRate = baseRate * 1.5 -- Psychic gets 50% more mana regen
    end
    
    return baseRate
end

-- Restore mana (for potions, healing, etc.)
function ManaSystem:restoreMana(player, amount)
    if not player or not player.mana then return false end
    
    local oldMana = player.mana
    player.mana = math.min(player.maxMana, player.mana + amount)
    local restored = player.mana - oldMana
    
    if restored > 0 then
        -- Create visual effect for mana restoration
        player.manaRestoreEffect = {
            amount = restored,
            startTime = love.timer.getTime(),
            duration = 1.0
        }
        return true
    end
    
    return false
end

-- Draw mana restoration effects
function ManaSystem:drawManaEffects(player)
    if not player or not player.manaRestoreEffect then return end
    
    local effect = player.manaRestoreEffect
    local elapsed = love.timer.getTime() - effect.startTime
    
    if elapsed < effect.duration then
        local alpha = 1.0 - (elapsed / effect.duration)
        local yOffset = -20 - (elapsed * 30) -- Float upward
        
        love.graphics.setColor(0.2, 0.4, 1.0, alpha)
        love.graphics.print("+" .. math.floor(effect.amount) .. " MP", 
                          player.x - 15, player.y + yOffset, 0, 0.8, 0.8)
    else
        player.manaRestoreEffect = nil
    end
end

return ManaSystem
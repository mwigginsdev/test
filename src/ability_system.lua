-- Ability System Framework - Handles cooldown-based special abilities

local AbilitySystem = {}
AbilitySystem.__index = AbilitySystem

function AbilitySystem:new()
    local system = setmetatable({}, AbilitySystem)
    
    -- Track active abilities and cooldowns per player
    system.playerAbilities = {}
    system.activeCooldowns = {}
    system.activeEffects = {}
    
    return system
end

-- Initialize abilities for a player
function AbilitySystem:initializePlayer(player)
    if not player then return end
    
    -- Ensure player has an ID
    if not player.id then
        player.id = tostring(love.timer.getTime()) .. "_" .. math.random(1000, 9999)
    end
    
    self.playerAbilities[player.id] = {}
    self.activeCooldowns[player.id] = {}
    self.activeEffects[player.id] = {}
    
    -- Load abilities from ship class
    if player.shipClass and player.shipClass.abilities then
        for i, ability in ipairs(player.shipClass.abilities) do
            self.playerAbilities[player.id][i] = {
                name = ability.name,
                description = ability.description,
                manaCost = ability.manaCost,
                cooldown = ability.cooldown,
                use = ability.use,
                lastUsed = 0
            }
            
            self.activeCooldowns[player.id][i] = 0
        end
        print("Loaded " .. #player.shipClass.abilities .. " abilities for " .. (player.shipClass.name or "Unknown Class"))
    end
end

-- Check if ability is ready to use
function AbilitySystem:isAbilityReady(player, abilityIndex)
    if not player or not player.id then return false end
    if not self.playerAbilities[player.id] then return false end
    if not self.playerAbilities[player.id][abilityIndex] then return false end
    
    local ability = self.playerAbilities[player.id][abilityIndex]
    local cooldownRemaining = self.activeCooldowns[player.id][abilityIndex] or 0
    
    -- Check cooldown
    if cooldownRemaining > 0 then return false end
    
    -- Check mana cost
    if player.mana < ability.manaCost then return false end
    
    return true
end

-- Use an ability
function AbilitySystem:useAbility(player, abilityIndex)
    if not self:isAbilityReady(player, abilityIndex) then
        return false
    end
    
    local ability = self.playerAbilities[player.id][abilityIndex]
    
    -- Consume mana
    player.mana = player.mana - ability.manaCost
    
    -- Start cooldown
    self.activeCooldowns[player.id][abilityIndex] = ability.cooldown
    
    -- Execute ability
    local success = false
    if ability.use and type(ability.use) == "function" then
        success = ability.use(player, player.shipClass)
    end
    
    if success then
        print("Ability used: " .. ability.name)
        ability.lastUsed = love.timer.getTime()
    else
        -- Refund mana if ability failed
        player.mana = player.mana + ability.manaCost
        self.activeCooldowns[player.id][abilityIndex] = 0
    end
    
    return success
end

-- Update cooldowns and effects
function AbilitySystem:update(dt)
    local currentTime = love.timer.getTime()
    
    -- Update cooldowns
    for playerId, cooldowns in pairs(self.activeCooldowns) do
        for abilityIndex, remaining in pairs(cooldowns) do
            if remaining > 0 then
                self.activeCooldowns[playerId][abilityIndex] = math.max(0, remaining - dt)
            end
        end
    end
    
    -- Update active effects (for future timed effects)
    for playerId, effects in pairs(self.activeEffects) do
        for effectId, effect in pairs(effects) do
            if effect.duration then
                effect.timeRemaining = effect.timeRemaining - dt
                if effect.timeRemaining <= 0 then
                    self:removeEffect(playerId, effectId)
                end
            end
        end
    end
end

-- Get cooldown remaining for ability
function AbilitySystem:getCooldownRemaining(player, abilityIndex)
    if not player or not player.id then return 0 end
    if not self.activeCooldowns[player.id] then return 0 end
    
    return self.activeCooldowns[player.id][abilityIndex] or 0
end

-- Get ability info
function AbilitySystem:getAbilityInfo(player, abilityIndex)
    if not player or not player.id then return nil end
    if not self.playerAbilities[player.id] then return nil end
    
    local ability = self.playerAbilities[player.id][abilityIndex]
    if not ability then return nil end
    
    return {
        name = ability.name,
        description = ability.description,
        manaCost = ability.manaCost,
        cooldown = ability.cooldown,
        cooldownRemaining = self:getCooldownRemaining(player, abilityIndex),
        canUse = self:isAbilityReady(player, abilityIndex)
    }
end

-- Add a timed effect to a player
function AbilitySystem:addEffect(player, effectId, effect)
    if not player or not player.id then return end
    
    if not self.activeEffects[player.id] then
        self.activeEffects[player.id] = {}
    end
    
    effect.timeRemaining = effect.duration or 0
    self.activeEffects[player.id][effectId] = effect
end

-- Remove an effect from a player
function AbilitySystem:removeEffect(playerId, effectId)
    if not self.activeEffects[playerId] then return end
    
    local effect = self.activeEffects[playerId][effectId]
    if effect and effect.onRemove then
        effect.onRemove()
    end
    
    self.activeEffects[playerId][effectId] = nil
end

-- Check if player has specific effect
function AbilitySystem:hasEffect(player, effectId)
    if not player or not player.id then return false end
    if not self.activeEffects[player.id] then return false end
    
    return self.activeEffects[player.id][effectId] ~= nil
end

-- Get all effects for a player
function AbilitySystem:getPlayerEffects(player)
    if not player or not player.id then return {} end
    return self.activeEffects[player.id] or {}
end

-- Clean up player data
function AbilitySystem:removePlayer(playerId)
    if not playerId then return end
    
    self.playerAbilities[playerId] = nil
    self.activeCooldowns[playerId] = nil
    self.activeEffects[playerId] = nil
end

-- Draw ability UI for a player
function AbilitySystem:drawAbilityUI(player, x, y)
    if not player or not player.id then return end
    if not self.playerAbilities[player.id] then return end
    
    local abilities = self.playerAbilities[player.id]
    local startX = x
    local abilitySize = 40
    local spacing = 45
    
    for i, ability in ipairs(abilities) do
        local abilityX = startX + (i - 1) * spacing
        local abilityY = y
        
        -- Ability slot background
        if self:isAbilityReady(player, i) then
            love.graphics.setColor(0.2, 0.8, 0.2, 0.8) -- Green if ready
        else
            love.graphics.setColor(0.8, 0.2, 0.2, 0.8) -- Red if not ready
        end
        love.graphics.rectangle('fill', abilityX, abilityY, abilitySize, abilitySize)
        
        -- Ability border
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle('line', abilityX, abilityY, abilitySize, abilitySize)
        
        -- Ability number
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(i), abilityX + 2, abilityY + 2)
        
        -- Cooldown overlay
        local cooldownRemaining = self:getCooldownRemaining(player, i)
        if cooldownRemaining > 0 then
            local progress = cooldownRemaining / ability.cooldown
            local overlayHeight = abilitySize * progress
            
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            love.graphics.rectangle('fill', abilityX, abilityY + abilitySize - overlayHeight, 
                                  abilitySize, overlayHeight)
            
            -- Cooldown text
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(string.format("%.1f", cooldownRemaining), 
                              abilityX + 4, abilityY + abilitySize/2)
        end
        
        -- Mana cost indicator
        if player.mana < ability.manaCost then
            love.graphics.setColor(0.5, 0.5, 1, 0.7)
            love.graphics.rectangle('fill', abilityX, abilityY, abilitySize, 6)
        end
    end
    
    -- Ability names on hover (simplified - would need mouse position)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Abilities: 1-4 keys", x, y - 20)
end

-- Get ability count for player
function AbilitySystem:getAbilityCount(player)
    if not player or not player.id then return 0 end
    if not self.playerAbilities[player.id] then return 0 end
    
    local count = 0
    for _ in pairs(self.playerAbilities[player.id]) do
        count = count + 1
    end
    return count
end

return AbilitySystem
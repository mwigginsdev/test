-- Status Effect System - Handles temporary character modifications

local StatusEffectSystem = {}
StatusEffectSystem.__index = StatusEffectSystem

function StatusEffectSystem:new()
    local system = setmetatable({}, StatusEffectSystem)
    
    -- Track active effects per entity
    system.activeEffects = {}
    
    -- Effect type definitions
    system.effectTypes = {
        paralyzed = {
            name = "Paralyzed",
            color = {0.8, 0.2, 0.8}, -- Purple
            icon = "⚡",
            stackable = false,
            description = "Cannot move or shoot"
        },
        slowed = {
            name = "Slowed",
            color = {0.2, 0.5, 0.8}, -- Blue
            icon = "❄",
            stackable = true,
            maxStacks = 3,
            description = "Movement speed reduced"
        },
        weakness = {
            name = "Weakness",
            color = {0.8, 0.6, 0.2}, -- Orange
            icon = "↓",
            stackable = false,
            description = "Damage output reduced"
        },
        armorBreak = {
            name = "Armor Break",
            color = {0.8, 0.2, 0.2}, -- Red
            icon = "🛡",
            stackable = false,
            description = "Increased damage taken"
        },
        bleeding = {
            name = "Bleeding",
            color = {0.9, 0.1, 0.1}, -- Dark red
            icon = "🩸",
            stackable = true,
            maxStacks = 3,
            description = "Taking damage over time"
        },
        confused = {
            name = "Confused",
            color = {0.6, 0.3, 0.9}, -- Light purple
            icon = "?",
            stackable = false,
            description = "Controls are reversed"
        },
        blind = {
            name = "Blind",
            color = {0.1, 0.1, 0.1}, -- Dark
            icon = "👁",
            stackable = false,
            description = "Vision severely reduced"
        }
    }
    
    return system
end

-- Apply a status effect to an entity
function StatusEffectSystem:applyEffect(entity, effectType, duration, intensity)
    if not entity or not entity.id then return false end
    if not self.effectTypes[effectType] then return false end
    
    local effectDef = self.effectTypes[effectType]
    duration = duration or 5.0
    intensity = intensity or 1.0
    
    -- Initialize effects for entity if needed
    if not self.activeEffects[entity.id] then
        self.activeEffects[entity.id] = {}
    end
    
    local effects = self.activeEffects[entity.id]
    
    -- Handle stacking
    if effectDef.stackable then
        -- Find existing effect or create new one
        local existingEffect = nil
        for _, effect in ipairs(effects) do
            if effect.type == effectType then
                existingEffect = effect
                break
            end
        end
        
        if existingEffect then
            -- Add stack and refresh duration
            existingEffect.stacks = math.min(existingEffect.stacks + 1, effectDef.maxStacks or 5)
            existingEffect.duration = math.max(existingEffect.duration, duration)
            existingEffect.intensity = existingEffect.intensity + intensity
        else
            -- Create new stacking effect
            table.insert(effects, {
                type = effectType,
                duration = duration,
                intensity = intensity,
                stacks = 1,
                startTime = love.timer.getTime(),
                lastTick = love.timer.getTime()
            })
        end
    else
        -- Non-stacking effect - replace existing
        local replaced = false
        for i, effect in ipairs(effects) do
            if effect.type == effectType then
                effect.duration = duration
                effect.intensity = intensity
                effect.startTime = love.timer.getTime()
                effect.lastTick = love.timer.getTime()
                replaced = true
                break
            end
        end
        
        if not replaced then
            table.insert(effects, {
                type = effectType,
                duration = duration,
                intensity = intensity,
                stacks = 1,
                startTime = love.timer.getTime(),
                lastTick = love.timer.getTime()
            })
        end
    end
    
    print("Applied " .. effectDef.name .. " to " .. (entity.name or "entity") .. " for " .. duration .. "s")
    return true
end

-- Remove a specific status effect
function StatusEffectSystem:removeEffect(entity, effectType)
    if not entity or not entity.id then return false end
    if not self.activeEffects[entity.id] then return false end
    
    local effects = self.activeEffects[entity.id]
    for i = #effects, 1, -1 do
        if effects[i].type == effectType then
            table.remove(effects, i)
            return true
        end
    end
    
    return false
end

-- Check if entity has a specific effect
function StatusEffectSystem:hasEffect(entity, effectType)
    if not entity or not entity.id then return false end
    if not self.activeEffects[entity.id] then return false end
    
    for _, effect in ipairs(self.activeEffects[entity.id]) do
        if effect.type == effectType then
            return true, effect
        end
    end
    
    return false
end

-- Get all effects for an entity
function StatusEffectSystem:getEffects(entity)
    if not entity or not entity.id then return {} end
    return self.activeEffects[entity.id] or {}
end

-- Update status effects
function StatusEffectSystem:update(dt)
    local currentTime = love.timer.getTime()
    
    for entityId, effects in pairs(self.activeEffects) do
        for i = #effects, 1, -1 do
            local effect = effects[i]
            
            -- Update duration
            effect.duration = effect.duration - dt
            
            -- Apply periodic effects (like bleeding)
            if effect.type == "bleeding" then
                local timeSinceLastTick = currentTime - effect.lastTick
                if timeSinceLastTick >= 1.0 then -- Tick every second
                    self:applyBleedingDamage(entityId, effect)
                    effect.lastTick = currentTime
                end
            end
            
            -- Remove expired effects
            if effect.duration <= 0 then
                table.remove(effects, i)
            end
        end
        
        -- Clean up empty effect lists
        if #effects == 0 then
            self.activeEffects[entityId] = nil
        end
    end
end

-- Apply bleeding damage
function StatusEffectSystem:applyBleedingDamage(entityId, effect)
    -- This would be called by the game to apply damage
    local damage = 10 * (effect.stacks or 1)
    print("Bleeding damage: " .. damage .. " to entity " .. entityId)
    
    -- The game would need to implement the actual damage application
    return damage
end

-- Get movement speed modifier for entity
function StatusEffectSystem:getSpeedModifier(entity)
    local modifier = 1.0
    
    if not entity or not entity.id then return modifier end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "paralyzed" then
            return 0.0 -- Complete immobilization
        elseif effect.type == "slowed" then
            local slowAmount = 0.5 * (effect.stacks or 1) -- 50% per stack
            modifier = modifier * (1.0 - math.min(slowAmount, 0.9)) -- Cap at 90% slow
        end
    end
    
    return modifier
end

-- Get damage modifier for entity
function StatusEffectSystem:getDamageModifier(entity)
    local modifier = 1.0
    
    if not entity or not entity.id then return modifier end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "weakness" then
            modifier = modifier * 0.75 -- 25% damage reduction
        end
    end
    
    return modifier
end

-- Get incoming damage modifier for entity
function StatusEffectSystem:getIncomingDamageModifier(entity)
    local modifier = 1.0
    
    if not entity or not entity.id then return modifier end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "armorBreak" then
            modifier = modifier * 1.5 -- 50% more damage taken
        end
    end
    
    return modifier
end

-- Check if entity can move
function StatusEffectSystem:canMove(entity)
    if not entity or not entity.id then return true end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "paralyzed" then
            return false
        end
    end
    
    return true
end

-- Check if entity can shoot
function StatusEffectSystem:canShoot(entity)
    if not entity or not entity.id then return true end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "paralyzed" then
            return false
        end
    end
    
    return true
end

-- Check if controls are confused
function StatusEffectSystem:isConfused(entity)
    if not entity or not entity.id then return false end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "confused" then
            return true
        end
    end
    
    return false
end

-- Get vision modifier (for blind effect)
function StatusEffectSystem:getVisionModifier(entity)
    if not entity or not entity.id then return 1.0 end
    
    local effects = self.activeEffects[entity.id] or {}
    
    for _, effect in ipairs(effects) do
        if effect.type == "blind" then
            return 0.2 -- 80% vision reduction
        end
    end
    
    return 1.0
end

-- Draw status effect indicators
function StatusEffectSystem:drawEffects(entity, x, y)
    if not entity or not entity.id then return end
    
    local effects = self.activeEffects[entity.id] or {}
    if #effects == 0 then return end
    
    local offsetX = 0
    local iconSize = 16
    local spacing = 20
    
    for _, effect in ipairs(effects) do
        local effectDef = self.effectTypes[effect.type]
        if effectDef then
            -- Effect background
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle('fill', x + offsetX - 2, y - 2, iconSize + 4, iconSize + 4)
            
            -- Effect color
            love.graphics.setColor(effectDef.color[1], effectDef.color[2], effectDef.color[3], 0.8)
            love.graphics.rectangle('fill', x + offsetX, y, iconSize, iconSize)
            
            -- Effect icon/text
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(effectDef.icon or "?", x + offsetX + 2, y + 2, 0, 0.7, 0.7)
            
            -- Stack count for stackable effects
            if effectDef.stackable and effect.stacks > 1 then
                love.graphics.print(tostring(effect.stacks), x + offsetX + 10, y + 8, 0, 0.6, 0.6)
            end
            
            -- Duration countdown
            if effect.duration < 5 then -- Show timer when < 5 seconds
                love.graphics.setColor(1, 1, 0)
                love.graphics.print(string.format("%.1f", effect.duration), 
                                  x + offsetX, y + iconSize + 2, 0, 0.5, 0.5)
            end
            
            offsetX = offsetX + spacing
        end
    end
end

-- Clean up effects for an entity (when it's removed)
function StatusEffectSystem:cleanupEntity(entityId)
    if self.activeEffects[entityId] then
        self.activeEffects[entityId] = nil
    end
end

-- Get effect summary for UI
function StatusEffectSystem:getEffectSummary(entity)
    if not entity or not entity.id then return "" end
    
    local effects = self.activeEffects[entity.id] or {}
    if #effects == 0 then return "No effects" end
    
    local summary = {}
    for _, effect in ipairs(effects) do
        local effectDef = self.effectTypes[effect.type]
        if effectDef then
            local text = effectDef.name
            if effectDef.stackable and effect.stacks > 1 then
                text = text .. " x" .. effect.stacks
            end
            text = text .. " (" .. string.format("%.1f", effect.duration) .. "s)"
            table.insert(summary, text)
        end
    end
    
    return table.concat(summary, ", ")
end

return StatusEffectSystem
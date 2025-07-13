-- Ship Class Manager - Handles all ship classes and class selection

local Fighter = require('src.classes.fighter')
local Interceptor = require('src.classes.interceptor')
local Bomber = require('src.classes.bomber')
local Support = require('src.classes.support')
local Stealth = require('src.classes.stealth')
local Tank = require('src.classes.tank')
local Engineer = require('src.classes.engineer')
local Psychic = require('src.classes.psychic')

local ShipClassManager = {}
ShipClassManager.__index = ShipClassManager

function ShipClassManager:new()
    local manager = setmetatable({}, ShipClassManager)
    
    -- Available ship classes
    manager.classes = {
        fighter = Fighter,
        interceptor = Interceptor,
        bomber = Bomber,
        support = Support,
        stealth = Stealth,
        tank = Tank,
        engineer = Engineer,
        psychic = Psychic
    }
    
    -- Class unlock requirements (for future use)
    manager.unlockRequirements = {
        fighter = {level = 1}, -- Always available
        interceptor = {level = 1}, -- Available at start for testing
        bomber = {level = 1}, -- Available at start for testing
        support = {level = 1}, -- Available at start for testing
        stealth = {level = 1}, -- Available at start for testing
        tank = {level = 1}, -- Available at start for testing
        engineer = {level = 1}, -- Available at start for testing
        psychic = {level = 1} -- Available for testing
    }
    
    return manager
end

function ShipClassManager:createClass(classType)
    local classConstructor = self.classes[classType]
    if not classConstructor then
        print("Warning: Unknown class type: " .. tostring(classType))
        return self.classes.fighter:new() -- Default to fighter
    end
    
    return classConstructor:new()
end

function ShipClassManager:getAvailableClasses(playerLevel)
    local available = {}
    
    for classType, requirements in pairs(self.unlockRequirements) do
        if playerLevel >= requirements.level and self.classes[classType] then
            table.insert(available, {
                type = classType,
                class = self.classes[classType]:new(),
                unlocked = true
            })
        else
            table.insert(available, {
                type = classType,
                class = self.classes[classType] and self.classes[classType]:new() or nil,
                unlocked = false,
                requiresLevel = requirements.level
            })
        end
    end
    
    return available
end

function ShipClassManager:isClassUnlocked(classType, playerLevel)
    local requirements = self.unlockRequirements[classType]
    if not requirements then return false end
    
    return playerLevel >= requirements.level
end

function ShipClassManager:getClassDescription(classType)
    local class = self:createClass(classType)
    return {
        name = class.name,
        description = class.description,
        stats = class.baseStats,
        abilities = class.abilities
    }
end

-- Apply class to player
function ShipClassManager:applyClassToPlayer(player, classType)
    if not player then return false end
    
    local shipClass = self:createClass(classType)
    shipClass:applyToPlayer(player)
    
    print("Applied " .. shipClass.name .. " class to player")
    return true
end

-- Update class-specific effects for player
function ShipClassManager:updatePlayer(player, dt)
    if not player or not player.shipClass then return end
    
    player.shipClass:update(player, dt)
end

-- Use class ability
function ShipClassManager:useAbility(player, abilityIndex)
    if not player or not player.shipClass then return false end
    
    return player.shipClass:useAbility(player, abilityIndex)
end

-- Draw class-specific UI
function ShipClassManager:drawClassUI(player, x, y)
    if not player or not player.shipClass then return end
    
    player.shipClass:drawUI(player, x, y)
end

-- Draw class-specific effects
function ShipClassManager:drawClassEffects(player)
    if not player or not player.shipClass then return end
    
    if player.shipClass.drawClassEffects then
        player.shipClass:drawClassEffects(player)
    end
end

-- Check if player can equip item
function ShipClassManager:canEquipItem(player, item)
    if not player or not player.shipClass then return true end
    
    return player.shipClass:canEquipItem(item)
end

-- Get effective stats with class modifiers
function ShipClassManager:getEffectiveStats(player)
    if not player or not player.shipClass then
        return {
            health = player.health or 100,
            attack = 20,
            defense = 5,
            speed = player.speed or 300
        }
    end
    
    return player.shipClass:getEffectiveStats(player)
end

-- Handle class-specific damage modifications
function ShipClassManager:modifyDamage(player, damage, damageType)
    if not player or not player.shipClass then return damage end
    
    -- Check for class-specific damage modifications
    if player.shipClass.modifyDamage then
        return player.shipClass:modifyDamage(player, damage, damageType)
    end
    
    -- Check for support shield boost
    if damageType == "incoming" and player.shipClass.type == "support" then
        local reduction = player.shipClass:getDamageReduction(player, player)
        return damage * (1 - reduction)
    end
    
    return damage
end

-- Get all class types
function ShipClassManager:getAllClassTypes()
    local types = {}
    for classType, _ in pairs(self.classes) do
        table.insert(types, classType)
    end
    return types
end

return ShipClassManager
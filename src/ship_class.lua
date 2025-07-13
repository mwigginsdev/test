-- Ship Class System for Terminal Drift
-- Base class system with 8 distinct ship classes inspired by RotMG

local ShipClass = {}
ShipClass.__index = ShipClass

-- Base Ship Class
function ShipClass:new(classType)
    local class = setmetatable({}, ShipClass)
    
    class.type = classType or "fighter"
    class.name = "Unknown Class"
    class.description = ""
    
    -- Base stats (modified by class)
    class.baseStats = {
        health = 100,
        maxHealth = 100,
        mana = 50,
        maxMana = 50,
        attack = 20,
        defense = 5,
        speed = 300,
        fireRate = 0.15,
        dexterity = 10, -- Affects fire rate and accuracy
        vitality = 10,  -- Affects health regen
        wisdom = 10     -- Affects mana regen
    }
    
    -- Stat caps (different per class)
    class.statCaps = {
        health = 200,
        mana = 100,
        attack = 50,
        defense = 25,
        speed = 500,
        dexterity = 75,
        vitality = 40,
        wisdom = 40
    }
    
    -- Equipment restrictions
    class.canEquip = {
        weapons = {"laser", "plasma", "missile"},
        armor = {"light", "medium", "heavy"},
        abilities = {"basic"}
    }
    
    -- Visual appearance
    class.shipShape = "triangle"
    class.shipColor = {0.5, 0.5, 0.5}
    class.shipSize = 1.0
    
    -- Special abilities
    class.abilities = {}
    
    -- Load class-specific configuration
    class:loadClassConfig()
    
    return class
end

function ShipClass:loadClassConfig()
    -- Override in subclasses
end

-- Apply class stats to a player instance
function ShipClass:applyToPlayer(player)
    if not player then return end
    
    -- Apply base stats
    player.health = self.baseStats.health
    player.maxHealth = self.baseStats.maxHealth
    player.mana = self.baseStats.mana or 50
    player.maxMana = self.baseStats.maxMana or 50
    player.speed = self.baseStats.speed
    player.fireRate = self.baseStats.fireRate
    
    -- Apply visual appearance
    player.shipShape = self.shipShape
    player.shipColor = self.shipColor
    
    -- Store class reference
    player.shipClass = self
    
    -- Add mana system if not present
    if not player.mana then
        player.mana = self.baseStats.mana
        player.maxMana = self.baseStats.maxMana
        player.manaRegen = 5 -- per second
    end
end

-- Get effective stats after equipment and bonuses
function ShipClass:getEffectiveStats(player)
    local stats = {}
    
    -- Copy base stats
    for key, value in pairs(self.baseStats) do
        stats[key] = value
    end
    
    -- Apply equipment bonuses (if player has equipment)
    if player and player.weapon1 then
        stats.attack = stats.attack + (player.weapon1.stats.damage or 0)
    end
    
    if player and player.shield then
        stats.defense = stats.defense + (player.shield.stats.defense or 0)
    end
    
    if player and player.engine then
        stats.speed = stats.speed + (player.engine.stats.speedBonus or 0)
    end
    
    -- Apply class-specific modifiers
    stats = self:applyClassModifiers(stats)
    
    return stats
end

function ShipClass:applyClassModifiers(stats)
    -- Override in subclasses
    return stats
end

-- Check if class can equip specific item
function ShipClass:canEquipItem(item)
    if not item or not item.type then return false end
    
    if item.type == "weapon" then
        return self:canEquipWeapon(item.weaponType or "laser")
    elseif item.type == "armor" then
        return self:canEquipArmor(item.armorType or "light")
    elseif item.type == "ability" then
        return self:canEquipAbility(item.abilityType or "basic")
    end
    
    return true -- Allow other item types by default
end

function ShipClass:canEquipWeapon(weaponType)
    for _, allowedType in ipairs(self.canEquip.weapons) do
        if allowedType == weaponType then
            return true
        end
    end
    return false
end

function ShipClass:canEquipArmor(armorType)
    for _, allowedType in ipairs(self.canEquip.armor) do
        if allowedType == armorType then
            return true
        end
    end
    return false
end

function ShipClass:canEquipAbility(abilityType)
    for _, allowedType in ipairs(self.canEquip.abilities) do
        if allowedType == abilityType then
            return true
        end
    end
    return false
end

-- Use class-specific ability
function ShipClass:useAbility(player, abilityIndex)
    if not player or not self.abilities[abilityIndex] then
        return false
    end
    
    local ability = self.abilities[abilityIndex]
    
    -- Check mana cost
    if player.mana < ability.manaCost then
        return false
    end
    
    -- Check cooldown
    local currentTime = love.timer.getTime()
    if player.lastAbilityUse and (currentTime - player.lastAbilityUse) < ability.cooldown then
        return false
    end
    
    -- Use ability
    local success = ability.use(player, self)
    
    if success then
        player.mana = player.mana - ability.manaCost
        player.lastAbilityUse = currentTime
    end
    
    return success
end

-- Update class-specific systems
function ShipClass:update(player, dt)
    if not player then return end
    
    -- Regenerate mana
    if player.mana < player.maxMana then
        local regenRate = self.baseStats.wisdom / 10 -- Wisdom affects mana regen
        player.mana = math.min(player.maxMana, player.mana + regenRate * dt)
    end
    
    -- Update class-specific effects
    self:updateClassEffects(player, dt)
end

function ShipClass:updateClassEffects(player, dt)
    -- Override in subclasses
end

-- Draw class-specific UI elements
function ShipClass:drawUI(player, x, y)
    if not player then return end
    
    -- Draw mana bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', x, y + 25, 200, 15)
    love.graphics.setColor(0, 0, 1)
    local manaPercent = player.mana / player.maxMana
    love.graphics.rectangle('fill', x, y + 25, 200 * manaPercent, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', x, y + 25, 200, 15)
    love.graphics.print("Mana: " .. math.floor(player.mana) .. "/" .. player.maxMana, x, y + 45)
    
    -- Draw class name
    love.graphics.setColor(self.shipColor)
    love.graphics.print("Class: " .. self.name, x, y + 65, 0, 1.2, 1.2)
    
    -- Draw abilities
    local abilityY = y + 85
    for i, ability in ipairs(self.abilities) do
        local canUse = player.mana >= ability.manaCost
        love.graphics.setColor(canUse and {0, 1, 0} or {0.5, 0.5, 0.5})
        love.graphics.print("[" .. i .. "] " .. ability.name, x, abilityY)
        abilityY = abilityY + 15
    end
    
    love.graphics.setColor(1, 1, 1)
end

return ShipClass
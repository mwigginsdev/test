-- Item system for weapons, shields, engines, and crew

local Item = {}
Item.__index = Item

function Item:new(itemType, name, rarity, stats, description)
    local item = setmetatable({}, Item)
    
    item.type = itemType -- "weapon", "shield", "engine", "crew"
    item.name = name
    item.rarity = rarity -- "common", "uncommon", "rare", "epic", "legendary"
    item.stats = stats or {}
    item.description = description or ""
    item.value = item:calculateValue()
    item.color = item:getRarityColor()
    
    return item
end

function Item:getRarityColor()
    local colors = {
        common = {0.8, 0.8, 0.8},
        uncommon = {0.3, 1, 0.3},
        rare = {0.3, 0.3, 1},
        epic = {0.8, 0.3, 1},
        legendary = {1, 0.8, 0.3}
    }
    return colors[self.rarity] or colors.common
end

function Item:calculateValue()
    local baseValues = {
        common = 100,
        uncommon = 250,
        rare = 500,
        epic = 1000,
        legendary = 2500
    }
    local base = baseValues[self.rarity] or 100
    
    -- Add value based on stats
    local statBonus = 0
    for _, value in pairs(self.stats) do
        if type(value) == "number" then
            statBonus = statBonus + math.abs(value) * 10
        end
    end
    
    return base + statBonus
end

-- Item generation functions
local ItemGenerator = {}

function ItemGenerator.generateWeapon(level)
    local level = level or 1
    local rarityRoll = math.random()
    local rarity = "common"
    
    if rarityRoll > 0.95 then rarity = "legendary"
    elseif rarityRoll > 0.85 then rarity = "epic"
    elseif rarityRoll > 0.65 then rarity = "rare"
    elseif rarityRoll > 0.35 then rarity = "uncommon"
    end
    
    local weaponTypes = {
        {name = "Pulse Laser", damage = 25, fireRate = 0.2, range = 300},
        {name = "Plasma Cannon", damage = 45, fireRate = 0.4, range = 250},
        {name = "Ion Blaster", damage = 35, fireRate = 0.15, range = 350},
        {name = "Missile Launcher", damage = 60, fireRate = 0.8, range = 400},
        {name = "Beam Rifle", damage = 30, fireRate = 0.1, range = 500}
    }
    
    local baseWeapon = weaponTypes[math.random(#weaponTypes)]
    local multiplier = 1 + (level - 1) * 0.1
    
    local rarityMultipliers = {
        common = 1.0,
        uncommon = 1.2,
        rare = 1.5,
        epic = 2.0,
        legendary = 3.0
    }
    
    local finalMultiplier = multiplier * rarityMultipliers[rarity]
    
    local stats = {
        damage = math.floor(baseWeapon.damage * finalMultiplier),
        fireRate = baseWeapon.fireRate / (1 + (finalMultiplier - 1) * 0.3),
        range = math.floor(baseWeapon.range * (1 + (finalMultiplier - 1) * 0.2))
    }
    
    local rarityPrefix = rarity == "common" and "" or string.upper(rarity:sub(1,1)) .. rarity:sub(2) .. " "
    local name = rarityPrefix .. baseWeapon.name
    
    return Item:new("weapon", name, rarity, stats, "DMG:" .. stats.damage .. " FR:" .. string.format("%.2f", stats.fireRate))
end

function ItemGenerator.generateShield(level)
    local level = level or 1
    local rarityRoll = math.random()
    local rarity = "common"
    
    if rarityRoll > 0.95 then rarity = "legendary"
    elseif rarityRoll > 0.85 then rarity = "epic"
    elseif rarityRoll > 0.65 then rarity = "rare"
    elseif rarityRoll > 0.35 then rarity = "uncommon"
    end
    
    local shieldTypes = {
        {name = "Energy Shield", capacity = 100, regenRate = 10},
        {name = "Plasma Barrier", capacity = 150, regenRate = 8},
        {name = "Kinetic Deflector", capacity = 120, regenRate = 12},
        {name = "Phase Shield", capacity = 80, regenRate = 15}
    }
    
    local baseShield = shieldTypes[math.random(#shieldTypes)]
    local multiplier = 1 + (level - 1) * 0.1
    
    local rarityMultipliers = {
        common = 1.0,
        uncommon = 1.3,
        rare = 1.7,
        epic = 2.2,
        legendary = 3.5
    }
    
    local finalMultiplier = multiplier * rarityMultipliers[rarity]
    
    local stats = {
        capacity = math.floor(baseShield.capacity * finalMultiplier),
        regenRate = math.floor(baseShield.regenRate * finalMultiplier)
    }
    
    local rarityPrefix = rarity == "common" and "" or string.upper(rarity:sub(1,1)) .. rarity:sub(2) .. " "
    local name = rarityPrefix .. baseShield.name
    
    return Item:new("shield", name, rarity, stats, "CAP:" .. stats.capacity .. " REGEN:" .. stats.regenRate)
end

function ItemGenerator.generateEngine(level)
    local level = level or 1
    local rarityRoll = math.random()
    local rarity = "common"
    
    if rarityRoll > 0.95 then rarity = "legendary"
    elseif rarityRoll > 0.85 then rarity = "epic"
    elseif rarityRoll > 0.65 then rarity = "rare"
    elseif rarityRoll > 0.35 then rarity = "uncommon"
    end
    
    local engineTypes = {
        {name = "Ion Drive", speed = 50, efficiency = 0.8},
        {name = "Fusion Engine", speed = 70, efficiency = 0.6},
        {name = "Antimatter Core", speed = 90, efficiency = 0.9},
        {name = "Quantum Thruster", speed = 60, efficiency = 1.0}
    }
    
    local baseEngine = engineTypes[math.random(#engineTypes)]
    local multiplier = 1 + (level - 1) * 0.1
    
    local rarityMultipliers = {
        common = 1.0,
        uncommon = 1.2,
        rare = 1.4,
        epic = 1.8,
        legendary = 2.5
    }
    
    local finalMultiplier = multiplier * rarityMultipliers[rarity]
    
    local stats = {
        speedBonus = math.floor(baseEngine.speed * finalMultiplier),
        efficiency = baseEngine.efficiency * finalMultiplier
    }
    
    local rarityPrefix = rarity == "common" and "" or string.upper(rarity:sub(1,1)) .. rarity:sub(2) .. " "
    local name = rarityPrefix .. baseEngine.name
    
    return Item:new("engine", name, rarity, stats, "SPD+" .. stats.speedBonus .. " EFF:" .. string.format("%.1f", stats.efficiency))
end

function ItemGenerator.generateCrew(level)
    local level = level or 1
    local rarityRoll = math.random()
    local rarity = "common"
    
    if rarityRoll > 0.95 then rarity = "legendary"
    elseif rarityRoll > 0.85 then rarity = "epic"
    elseif rarityRoll > 0.65 then rarity = "rare"
    elseif rarityRoll > 0.35 then rarity = "uncommon"
    end
    
    local crewTypes = {
        {name = "Engineer", skill = "repair", bonus = 0.2},
        {name = "Gunner", skill = "damage", bonus = 0.15},
        {name = "Pilot", skill = "speed", bonus = 0.25},
        {name = "Navigator", skill = "range", bonus = 0.3},
        {name = "Medic", skill = "healing", bonus = 0.1}
    }
    
    local baseCrew = crewTypes[math.random(#crewTypes)]
    local multiplier = 1 + (level - 1) * 0.05
    
    local rarityMultipliers = {
        common = 1.0,
        uncommon = 1.5,
        rare = 2.0,
        epic = 3.0,
        legendary = 5.0
    }
    
    local finalMultiplier = multiplier * rarityMultipliers[rarity]
    
    local stats = {
        skill = baseCrew.skill,
        bonus = baseCrew.bonus * finalMultiplier,
        hiringCost = math.floor(500 * finalMultiplier)
    }
    
    local rarityPrefix = rarity == "common" and "" or string.upper(rarity:sub(1,1)) .. rarity:sub(2) .. " "
    local name = rarityPrefix .. baseCrew.name
    
    return Item:new("crew", name, rarity, stats, baseCrew.skill:upper() .. "+" .. string.format("%.0f%%", stats.bonus * 100))
end

-- Export both Item class and ItemGenerator
return {
    Item = Item,
    ItemGenerator = ItemGenerator
}
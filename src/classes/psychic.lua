-- Psychic Class - Energy-based attacks and teleportation

local ShipClass = require('src.ship_class')

local Psychic = {}
Psychic.__index = Psychic
setmetatable(Psychic, {__index = ShipClass})

function Psychic:new()
    local psychic = setmetatable({}, Psychic)
    psychic.type = "psychic"
    psychic:loadClassConfig()
    return psychic
end

function Psychic:loadClassConfig()
    self.name = "Psychic"
    self.description = "Mind-powered ship with teleportation and energy manipulation"
    
    -- Balanced with focus on mobility and mana
    self.baseStats = {
        health = 100,
        maxHealth = 100,
        mana = 100,
        maxMana = 100,
        attack = 20,
        defense = 6,
        speed = 320,
        fireRate = 0.16,
        dexterity = 15,
        vitality = 12,
        wisdom = 20
    }
    
    self.statCaps = {
        health = 220,
        mana = 200,
        attack = 50,
        defense = 22,
        speed = 450,
        dexterity = 60,
        vitality = 40,
        wisdom = 75
    }
    
    -- Energy-based equipment
    self.canEquip = {
        weapons = {"energy", "psychic", "plasma"},
        armor = {"light", "energy"},
        abilities = {"psychic", "energy", "teleportation"}
    }
    
    -- Visual appearance
    self.shipShape = "star"
    self.shipColor = {0.8, 0.2, 1.0} -- Bright purple
    self.shipSize = 0.9
    
    -- Psychic abilities
    self.abilities = {
        {
            name = "Teleport",
            description = "Instantly move to target location within range",
            manaCost = 50,
            cooldown = 20,
            use = function(player, class)
                return class:useTeleport(player)
            end
        }
    }
end

function Psychic:useTeleport(player)
    if not player then return false end
    
    -- Get mouse position for teleport target
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- Calculate distance to target
    local dx = mouseX - player.x
    local dy = mouseY - player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Maximum teleport range
    local maxRange = 300
    
    -- If too far, teleport maximum distance in that direction
    if distance > maxRange then
        local angle = math.atan2(dy, dx)
        mouseX = player.x + math.cos(angle) * maxRange
        mouseY = player.y + math.sin(angle) * maxRange
    end
    
    -- Store teleport effect for visual
    player.teleportEffect = {
        fromX = player.x,
        fromY = player.y,
        toX = mouseX,
        toY = mouseY,
        startTime = love.timer.getTime(),
        duration = 0.5
    }
    
    -- Teleport player
    player.x = mouseX
    player.y = mouseY
    
    print("Psychic: Teleported!")
    return true
end

function Psychic:applyClassModifiers(stats)
    -- Psychic gets wisdom and mana bonus, health penalty
    stats.wisdom = stats.wisdom * 1.4
    stats.mana = stats.mana * 1.25
    stats.maxMana = stats.maxMana * 1.25
    stats.health = stats.health * 0.95
    stats.speed = stats.speed * 1.05
    
    return stats
end

function Psychic:updateClassEffects(player, dt)
    if not player then return end
    
    -- Update teleport effect
    if player.teleportEffect then
        local elapsed = love.timer.getTime() - player.teleportEffect.startTime
        if elapsed >= player.teleportEffect.duration then
            player.teleportEffect = nil
        end
    end
    
    -- Passive mana regeneration boost
    if player.mana < player.maxMana then
        local regenBonus = 5 -- Extra mana per second
        player.mana = math.min(player.maxMana, player.mana + regenBonus * dt)
    end
    
    -- Energy aura effect
    player.energyAura = {
        intensity = 0.5 + 0.3 * math.sin(love.timer.getTime() * 3),
        radius = player.radius + 8
    }
end

-- Enhanced bullet creation with energy effects
function Psychic:createEnergyBullet(player, targetX, targetY)
    if not player then return nil end
    
    local dx = targetX - player.x
    local dy = targetY - player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance == 0 then return nil end
    
    -- Normalize direction
    dx = dx / distance
    dy = dy / distance
    
    local bullet = {
        x = player.x + dx * (player.radius + 5),
        y = player.y + dy * (player.radius + 5),
        dx = dx * 500, -- Bullet speed
        dy = dy * 500,
        damage = player.attack * 1.2, -- Psychic bonus
        owner = player,
        type = "energy",
        lifetime = 3.0,
        createdAt = love.timer.getTime(),
        energyTrail = {}
    }
    
    return bullet
end

function Psychic:drawClassEffects(player)
    if not player then return end
    
    -- Draw energy aura
    if player.energyAura then
        local alpha = player.energyAura.intensity * 0.3
        love.graphics.setColor(0.8, 0.2, 1.0, alpha)
        love.graphics.circle('line', player.x, player.y, player.energyAura.radius)
        love.graphics.circle('line', player.x, player.y, player.energyAura.radius * 0.7)
        
        -- Energy particles around ship
        for i = 1, 6 do
            local angle = (i / 6) * 2 * math.pi + love.timer.getTime() * 2
            local radius = player.energyAura.radius * 0.8
            local particleX = player.x + math.cos(angle) * radius
            local particleY = player.y + math.sin(angle) * radius
            
            love.graphics.setColor(0.8, 0.4, 1.0, alpha * 2)
            love.graphics.circle('fill', particleX, particleY, 2)
        end
    end
    
    -- Draw teleport effect
    if player.teleportEffect then
        local effect = player.teleportEffect
        local elapsed = love.timer.getTime() - effect.startTime
        local progress = elapsed / effect.duration
        
        if progress <= 1.0 then
            -- Fade out effect
            local alpha = 1.0 - progress
            
            -- Draw teleport trail
            love.graphics.setColor(0.8, 0.2, 1.0, alpha)
            love.graphics.line(effect.fromX, effect.fromY, effect.toX, effect.toY)
            
            -- Energy burst at departure point
            love.graphics.setColor(1.0, 0.5, 1.0, alpha * 0.5)
            love.graphics.circle('line', effect.fromX, effect.fromY, 30 * (1 - progress))
            love.graphics.circle('line', effect.fromX, effect.fromY, 20 * (1 - progress))
            
            -- Energy burst at arrival point
            love.graphics.setColor(0.8, 0.2, 1.0, alpha * 0.7)
            love.graphics.circle('line', effect.toX, effect.toY, 25 * progress)
            love.graphics.circle('line', effect.toX, effect.toY, 15 * progress)
        end
    end
    
    -- Draw psychic indicator
    love.graphics.setColor(0.8, 0.2, 1.0, 0.2)
    love.graphics.circle('line', player.x, player.y, player.radius + 4)
end

-- Special psychic damage calculation
function Psychic:modifyBulletDamage(player, baseDamage, target)
    if not player then return baseDamage end
    
    -- Bonus damage based on current mana percentage
    local manaPercent = player.mana / player.maxMana
    local manaBonus = 1.0 + (manaPercent * 0.3) -- Up to 30% bonus at full mana
    
    return baseDamage * manaBonus
end

-- Draw energy bullets differently
function Psychic:drawEnergyBullet(bullet)
    if not bullet or bullet.type ~= "energy" then return end
    
    -- Main energy core
    love.graphics.setColor(0.8, 0.2, 1.0)
    love.graphics.circle('fill', bullet.x, bullet.y, 4)
    
    -- Outer energy glow
    love.graphics.setColor(1.0, 0.5, 1.0, 0.5)
    love.graphics.circle('fill', bullet.x, bullet.y, 6)
    
    -- Energy trail
    if not bullet.energyTrail then bullet.energyTrail = {} end
    
    -- Add current position to trail
    table.insert(bullet.energyTrail, {x = bullet.x, y = bullet.y, time = love.timer.getTime()})
    
    -- Remove old trail points
    local currentTime = love.timer.getTime()
    for i = #bullet.energyTrail, 1, -1 do
        if currentTime - bullet.energyTrail[i].time > 0.3 then
            table.remove(bullet.energyTrail, i)
        end
    end
    
    -- Draw trail
    for i, point in ipairs(bullet.energyTrail) do
        local age = currentTime - point.time
        local alpha = (0.3 - age) / 0.3
        love.graphics.setColor(0.8, 0.4, 1.0, alpha * 0.6)
        love.graphics.circle('fill', point.x, point.y, 2)
    end
end

return Psychic
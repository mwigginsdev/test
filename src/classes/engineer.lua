-- Engineer Class - Deployable structures and repair abilities

local ShipClass = require('src.ship_class')

local Engineer = {}
Engineer.__index = Engineer
setmetatable(Engineer, {__index = ShipClass})

function Engineer:new()
    local engineer = setmetatable({}, Engineer)
    engineer.type = "engineer"
    engineer:loadClassConfig()
    return engineer
end

function Engineer:loadClassConfig()
    self.name = "Engineer"
    self.description = "Technical specialist with deployable turrets and repair abilities"
    
    -- Balanced with focus on utility
    self.baseStats = {
        health = 120,
        maxHealth = 120,
        mana = 70,
        maxMana = 70,
        attack = 16,
        defense = 8,
        speed = 280,
        fireRate = 0.2,
        dexterity = 8,
        vitality = 14,
        wisdom = 18
    }
    
    self.statCaps = {
        health = 240,
        mana = 140,
        attack = 40,
        defense = 25,
        speed = 380,
        dexterity = 55,
        vitality = 45,
        wisdom = 55
    }
    
    -- Technical equipment
    self.canEquip = {
        weapons = {"laser", "tech", "repair", "utility"},
        armor = {"light", "medium", "tech"},
        abilities = {"engineering", "utility", "repair"}
    }
    
    -- Visual appearance
    self.shipShape = "pentagon"
    self.shipColor = {1.0, 0.6, 0.2} -- Orange
    self.shipSize = 1.0
    
    -- Engineer abilities
    self.abilities = {
        {
            name = "Deploy Turret",
            description = "Deploy an automated turret that lasts 30 seconds",
            manaCost = 50,
            cooldown = 40,
            use = function(player, class)
                return class:deployTurret(player)
            end
        }
    }
end

function Engineer:deployTurret(player)
    if not player then return false end
    
    -- Initialize turrets array if needed
    if not player.turrets then
        player.turrets = {}
    end
    
    -- Limit number of turrets
    if #player.turrets >= 2 then
        print("Engineer: Maximum turrets deployed")
        return false
    end
    
    -- Deploy turret at player location
    local turret = {
        x = player.x + math.random(-30, 30),
        y = player.y + math.random(-30, 30),
        health = 40,
        maxHealth = 40,
        damage = 15,
        range = 150,
        fireRate = 0.5,
        lastShot = 0,
        lifetime = 30.0,
        createdAt = love.timer.getTime(),
        active = true
    }
    
    table.insert(player.turrets, turret)
    print("Engineer: Turret deployed!")
    return true
end

function Engineer:applyClassModifiers(stats)
    -- Engineer gets wisdom bonus for better turrets
    stats.wisdom = stats.wisdom * 1.3
    stats.defense = stats.defense * 1.1
    
    return stats
end

function Engineer:updateClassEffects(player, dt)
    if not player or not player.turrets then return end
    
    -- Update turrets
    for i = #player.turrets, 1, -1 do
        local turret = player.turrets[i]
        
        -- Check lifetime
        local elapsed = love.timer.getTime() - turret.createdAt
        if elapsed >= turret.lifetime or turret.health <= 0 then
            table.remove(player.turrets, i)
            print("Engineer: Turret destroyed/expired")
        else
            -- Update turret
            self:updateTurret(turret, dt)
        end
    end
end

function Engineer:updateTurret(turret, dt)
    if not turret or not turret.active then return end
    
    turret.lastShot = turret.lastShot + dt
    
    -- Turret AI would go here (finding targets, shooting)
    -- For now, just visual updates
end

-- Get turret targets (would be used by game logic)
function Engineer:getTurretTargets(player, enemies)
    local targets = {}
    
    if not player or not player.turrets or not enemies then
        return targets
    end
    
    for _, turret in ipairs(player.turrets) do
        if turret.active then
            -- Find enemies in range
            for _, enemy in ipairs(enemies) do
                local dx = enemy.x - turret.x
                local dy = enemy.y - turret.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance <= turret.range then
                    table.insert(targets, {
                        turret = turret,
                        enemy = enemy,
                        distance = distance
                    })
                end
            end
        end
    end
    
    return targets
end

function Engineer:drawClassEffects(player)
    if not player then return end
    
    -- Draw turrets
    if player.turrets then
        for _, turret in ipairs(player.turrets) do
            self:drawTurret(turret)
        end
    end
    
    -- Draw engineering indicator
    love.graphics.setColor(1.0, 0.6, 0.2, 0.3)
    love.graphics.circle('line', player.x, player.y, player.radius + 6)
end

function Engineer:drawTurret(turret)
    if not turret or not turret.active then return end
    
    -- Turret base
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.circle('fill', turret.x, turret.y, 8)
    
    -- Turret cannon
    love.graphics.setColor(1.0, 0.6, 0.2)
    love.graphics.circle('fill', turret.x, turret.y, 5)
    
    -- Turret range indicator (subtle)
    love.graphics.setColor(1.0, 0.6, 0.2, 0.1)
    love.graphics.circle('line', turret.x, turret.y, turret.range)
    
    -- Health bar
    local healthPercent = turret.health / turret.maxHealth
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', turret.x - 15, turret.y - 20, 30, 4)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle('fill', turret.x - 15, turret.y - 20, 30 * healthPercent, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', turret.x - 15, turret.y - 20, 30, 4)
    
    -- Lifetime indicator
    local elapsed = love.timer.getTime() - turret.createdAt
    local remaining = turret.lifetime - elapsed
    if remaining < 5 then -- Show timer when < 5 seconds left
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.print(string.format("%.1f", remaining), turret.x - 8, turret.y + 15, 0, 0.7, 0.7)
    end
end

-- Damage turret
function Engineer:damageTurret(player, turretIndex, damage)
    if not player or not player.turrets or not player.turrets[turretIndex] then
        return false
    end
    
    local turret = player.turrets[turretIndex]
    turret.health = turret.health - damage
    
    if turret.health <= 0 then
        turret.active = false
        return true -- Turret destroyed
    end
    
    return false
end

return Engineer
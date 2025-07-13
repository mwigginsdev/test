-- Weapon Pattern System - Handles complex projectile patterns and advanced weapon mechanics

local WeaponPatternSystem = {}
WeaponPatternSystem.__index = WeaponPatternSystem

function WeaponPatternSystem:new()
    local system = setmetatable({}, WeaponPatternSystem)
    
    -- Pattern templates
    system.patterns = {
        single = {
            name = "Single Shot",
            bullets = 1,
            angleSpread = 0,
            generator = function(self, x, y, angle, bullets)
                return {{x = x, y = y, angle = angle}}
            end
        },
        
        spread = {
            name = "Spread Shot",
            bullets = 3,
            angleSpread = math.pi/6, -- 30 degrees
            generator = function(self, x, y, angle, bullets)
                local positions = {}
                local spreadAngle = self.angleSpread / (bullets - 1)
                local startAngle = angle - self.angleSpread/2
                
                for i = 1, bullets do
                    local bulletAngle = startAngle + (i-1) * spreadAngle
                    table.insert(positions, {x = x, y = y, angle = bulletAngle})
                end
                return positions
            end
        },
        
        burst = {
            name = "Burst Fire",
            bullets = 5,
            angleSpread = math.pi/4, -- 45 degrees
            generator = function(self, x, y, angle, bullets)
                local positions = {}
                local spreadAngle = self.angleSpread / (bullets - 1)
                local startAngle = angle - self.angleSpread/2
                
                for i = 1, bullets do
                    local bulletAngle = startAngle + (i-1) * spreadAngle
                    table.insert(positions, {x = x, y = y, angle = bulletAngle})
                end
                return positions
            end
        },
        
        spiral = {
            name = "Spiral Shot",
            bullets = 8,
            angleSpread = math.pi * 2, -- Full circle
            generator = function(self, x, y, angle, bullets)
                local positions = {}
                local angleStep = self.angleSpread / bullets
                
                for i = 1, bullets do
                    local bulletAngle = angle + (i-1) * angleStep
                    table.insert(positions, {x = x, y = y, angle = bulletAngle})
                end
                return positions
            end
        },
        
        wave = {
            name = "Wave Shot",
            bullets = 7,
            angleSpread = math.pi/3, -- 60 degrees
            generator = function(self, x, y, angle, bullets)
                local positions = {}
                local spreadAngle = self.angleSpread / (bullets - 1)
                local startAngle = angle - self.angleSpread/2
                
                for i = 1, bullets do
                    local bulletAngle = startAngle + (i-1) * spreadAngle
                    -- Add wave offset to position
                    local waveOffset = math.sin(i * math.pi/3) * 20
                    local offsetX = math.cos(bulletAngle + math.pi/2) * waveOffset
                    local offsetY = math.sin(bulletAngle + math.pi/2) * waveOffset
                    
                    table.insert(positions, {
                        x = x + offsetX, 
                        y = y + offsetY, 
                        angle = bulletAngle
                    })
                end
                return positions
            end
        }
    }
    
    -- Weapon types with different mechanics
    system.weaponTypes = {
        basic = {
            name = "Basic Laser",
            pattern = "single",
            damage = 20,
            speed = 500,
            fireRate = 0.3,
            piercing = false,
            aoe = false,
            statusEffect = nil
        },
        
        spreadGun = {
            name = "Spread Gun",
            pattern = "spread",
            damage = 15,
            speed = 450,
            fireRate = 0.4,
            piercing = false,
            aoe = false,
            statusEffect = nil
        },
        
        burstRifle = {
            name = "Burst Rifle",
            pattern = "burst",
            damage = 12,
            speed = 600,
            fireRate = 0.6,
            piercing = false,
            aoe = false,
            statusEffect = nil
        },
        
        spiralCannon = {
            name = "Spiral Cannon",
            pattern = "spiral",
            damage = 18,
            speed = 400,
            fireRate = 0.8,
            piercing = false,
            aoe = false,
            statusEffect = nil
        },
        
        waveBeam = {
            name = "Wave Beam",
            pattern = "wave",
            damage = 16,
            speed = 520,
            fireRate = 0.5,
            piercing = false,
            aoe = false,
            statusEffect = nil
        },
        
        piercingRail = {
            name = "Piercing Rail Gun",
            pattern = "single",
            damage = 35,
            speed = 800,
            fireRate = 1.0,
            piercing = true,
            maxPiercing = 5,
            aoe = false,
            statusEffect = nil
        },
        
        explosiveCannon = {
            name = "Explosive Cannon",
            pattern = "single",
            damage = 40,
            speed = 300,
            fireRate = 1.2,
            piercing = false,
            aoe = true,
            aoeRadius = 80,
            aoeFalloff = 0.5,
            statusEffect = nil
        },
        
        poisonDart = {
            name = "Poison Dart Gun",
            pattern = "spread",
            damage = 10,
            speed = 400,
            fireRate = 0.4,
            piercing = false,
            aoe = false,
            statusEffect = {
                type = "bleeding",
                chance = 0.6,
                duration = 4.0
            }
        },
        
        slowBeam = {
            name = "Cryogenic Beam",
            pattern = "single",
            damage = 15,
            speed = 450,
            fireRate = 0.3,
            piercing = false,
            aoe = false,
            statusEffect = {
                type = "slowed",
                chance = 0.8,
                duration = 3.0
            }
        }
    }
    
    return system
end

-- Create bullets based on weapon type and pattern
function WeaponPatternSystem:createBullets(weaponType, x, y, targetAngle, owner)
    local weapon = self.weaponTypes[weaponType]
    if not weapon then
        weapon = self.weaponTypes.basic
    end
    
    local pattern = self.patterns[weapon.pattern]
    if not pattern then
        pattern = self.patterns.single
    end
    
    -- Generate bullet positions using pattern
    local bulletPositions = pattern:generator(x, y, targetAngle, pattern.bullets)
    local bullets = {}
    
    for _, pos in ipairs(bulletPositions) do
        local bullet = self:createBullet(weapon, pos.x, pos.y, pos.angle, owner)
        table.insert(bullets, bullet)
    end
    
    return bullets
end

-- Create individual bullet with weapon properties
function WeaponPatternSystem:createBullet(weapon, x, y, angle, owner)
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    
    local bullet = {
        x = x,
        y = y,
        dx = dx * weapon.speed,
        dy = dy * weapon.speed,
        angle = angle,
        damage = weapon.damage,
        speed = weapon.speed,
        owner = owner,
        active = true,
        lifetime = 5.0,
        createdAt = love.timer.getTime(),
        
        -- Advanced properties
        piercing = weapon.piercing or false,
        maxPiercing = weapon.maxPiercing or 0,
        piercedTargets = {},
        
        aoe = weapon.aoe or false,
        aoeRadius = weapon.aoeRadius or 0,
        aoeFalloff = weapon.aoeFalloff or 0,
        
        statusEffect = weapon.statusEffect,
        
        weaponType = weapon.name,
        trail = {}
    }
    
    return bullet
end

-- Update bullet (handles piercing and special effects)
function WeaponPatternSystem:updateBullet(bullet, dt)
    if not bullet.active then return end
    
    -- Update position
    bullet.x = bullet.x + bullet.dx * dt
    bullet.y = bullet.y + bullet.dy * dt
    
    -- Update lifetime
    bullet.lifetime = bullet.lifetime - dt
    if bullet.lifetime <= 0 then
        bullet.active = false
        return
    end
    
    -- Update trail for visual effects
    table.insert(bullet.trail, {x = bullet.x, y = bullet.y, time = love.timer.getTime()})
    
    -- Remove old trail points
    local currentTime = love.timer.getTime()
    for i = #bullet.trail, 1, -1 do
        if currentTime - bullet.trail[i].time > 0.3 then
            table.remove(bullet.trail, i)
        end
    end
end

-- Check collision with piercing logic
function WeaponPatternSystem:checkCollision(bullet, target)
    if not bullet.active or not target then return false end
    
    -- Check if already pierced this target
    if bullet.piercing then
        for _, piercedId in ipairs(bullet.piercedTargets) do
            if piercedId == target.id then
                return false -- Already hit this target
            end
        end
    end
    
    -- Basic collision detection
    local dx = bullet.x - target.x
    local dy = bullet.y - target.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local targetRadius = target.radius or 15
    
    if distance < targetRadius + 3 then
        return true
    end
    
    return false
end

-- Apply bullet damage and effects
function WeaponPatternSystem:applyBulletHit(bullet, target, statusEffectSystem, defensiveSystem)
    if not bullet.active or not target then return 0 end
    
    local damage = bullet.damage
    
    -- Handle piercing
    if bullet.piercing then
        table.insert(bullet.piercedTargets, target.id)
        
        -- Reduce damage for each pierced target
        local pierceCount = #bullet.piercedTargets
        damage = damage * math.max(0.3, 1.0 - (pierceCount - 1) * 0.2)
        
        -- Stop piercing if max reached
        if pierceCount >= bullet.maxPiercing then
            bullet.active = false
        end
    else
        bullet.active = false
    end
    
    -- Apply status effect
    if bullet.statusEffect and statusEffectSystem then
        local chance = bullet.statusEffect.chance or 1.0
        if math.random() < chance then
            statusEffectSystem:applyEffect(
                target, 
                bullet.statusEffect.type, 
                bullet.statusEffect.duration,
                1.0,
                defensiveSystem
            )
        end
    end
    
    -- Handle AoE damage
    if bullet.aoe then
        damage = self:applyAoEDamage(bullet, target, statusEffectSystem, defensiveSystem)
    end
    
    return damage
end

-- Apply Area of Effect damage
function WeaponPatternSystem:applyAoEDamage(bullet, primaryTarget, statusEffectSystem, defensiveSystem)
    -- This would need to be integrated with the enemy manager
    -- For now, just return the primary damage
    local damage = bullet.damage
    
    print("AoE explosion at " .. bullet.x .. ", " .. bullet.y .. " radius: " .. bullet.aoeRadius)
    
    return damage
end

-- Draw bullet with enhanced visuals
function WeaponPatternSystem:drawBullet(bullet)
    if not bullet.active then return end
    
    -- Draw trail
    if #bullet.trail > 1 then
        love.graphics.setColor(0.8, 0.8, 1.0, 0.3)
        for i = 2, #bullet.trail do
            local prev = bullet.trail[i-1]
            local curr = bullet.trail[i]
            love.graphics.line(prev.x, prev.y, curr.x, curr.y)
        end
    end
    
    -- Draw bullet based on type
    if bullet.piercing then
        -- Piercing bullets are elongated
        love.graphics.setColor(1, 1, 0)
        love.graphics.push()
        love.graphics.translate(bullet.x, bullet.y)
        love.graphics.rotate(bullet.angle)
        love.graphics.rectangle('fill', -8, -2, 16, 4)
        love.graphics.pop()
    elseif bullet.aoe then
        -- Explosive bullets are larger
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.circle('fill', bullet.x, bullet.y, 6)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle('line', bullet.x, bullet.y, 8)
    elseif bullet.statusEffect then
        -- Status bullets have special colors
        if bullet.statusEffect.type == "bleeding" then
            love.graphics.setColor(0.8, 0.1, 0.1)
        elseif bullet.statusEffect.type == "slowed" then
            love.graphics.setColor(0.2, 0.5, 1.0)
        else
            love.graphics.setColor(0.8, 0.2, 0.8)
        end
        love.graphics.circle('fill', bullet.x, bullet.y, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle('line', bullet.x, bullet.y, 6)
    else
        -- Regular bullets
        love.graphics.setColor(0.2, 0.8, 1.0)
        love.graphics.circle('fill', bullet.x, bullet.y, 3)
    end
end

-- Get all available weapon types
function WeaponPatternSystem:getWeaponTypes()
    local types = {}
    for weaponType, weapon in pairs(self.weaponTypes) do
        table.insert(types, {
            id = weaponType,
            name = weapon.name,
            damage = weapon.damage,
            fireRate = weapon.fireRate,
            special = self:getWeaponSpecialText(weapon)
        })
    end
    return types
end

-- Get special properties text for weapon
function WeaponPatternSystem:getWeaponSpecialText(weapon)
    local specials = {}
    
    if weapon.piercing then
        table.insert(specials, "Piercing")
    end
    if weapon.aoe then
        table.insert(specials, "Explosive")
    end
    if weapon.statusEffect then
        table.insert(specials, "Status: " .. weapon.statusEffect.type)
    end
    if weapon.pattern ~= "single" then
        table.insert(specials, "Pattern: " .. weapon.pattern)
    end
    
    return #specials > 0 and table.concat(specials, ", ") or "Basic"
end

return WeaponPatternSystem
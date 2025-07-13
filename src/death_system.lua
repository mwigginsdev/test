-- Death System - Handles permadeath mechanics and grace periods

local DeathSystem = {}
DeathSystem.__index = DeathSystem

function DeathSystem:new()
    local system = setmetatable({}, DeathSystem)
    
    system.gracePeriod = 5.0 -- 5 seconds grace period
    system.dyingPlayers = {} -- Track players in death state
    
    return system
end

-- Mark player as dying (enters grace period)
function DeathSystem:markPlayerDying(player, causeOfDeath)
    if not player or not player.id then return end
    
    -- Don't mark already dying players
    if self.dyingPlayers[player.id] then return end
    
    -- Set player health to 0 but keep them alive during grace period
    player.health = 0
    player.isDying = true
    
    -- Track death state
    self.dyingPlayers[player.id] = {
        player = player,
        timeOfDeath = love.timer.getTime(),
        causeOfDeath = causeOfDeath or "Unknown",
        canBeHealed = true,
        graceTimeRemaining = self.gracePeriod
    }
    
    print("Player " .. (player.name or "Unknown") .. " is dying! Grace period: " .. self.gracePeriod .. "s")
    
    -- Visual/audio feedback for near-death
    self:triggerDeathWarning(player)
end

-- Attempt to heal a dying player
function DeathSystem:healDyingPlayer(player, healAmount)
    if not player or not player.id then return false end
    
    local deathState = self.dyingPlayers[player.id]
    if not deathState or not deathState.canBeHealed then return false end
    
    -- Successfully healed during grace period
    player.health = healAmount
    player.isDying = false
    
    -- Remove from dying players
    self.dyingPlayers[player.id] = nil
    
    print("Player " .. (player.name or "Unknown") .. " was saved by healing!")
    
    -- Visual feedback for successful rescue
    player.savedEffect = {
        startTime = love.timer.getTime(),
        duration = 2.0
    }
    
    return true
end

-- Update death system
function DeathSystem:update(dt)
    local currentTime = love.timer.getTime()
    
    for playerId, deathState in pairs(self.dyingPlayers) do
        local elapsed = currentTime - deathState.timeOfDeath
        deathState.graceTimeRemaining = self.gracePeriod - elapsed
        
        -- Check if grace period has expired
        if elapsed >= self.gracePeriod then
            self:finalizePlayerDeath(deathState.player, deathState.causeOfDeath)
            self.dyingPlayers[playerId] = nil
        end
    end
end

-- Finalize permanent death
function DeathSystem:finalizePlayerDeath(player, causeOfDeath)
    if not player then return end
    
    print("Player " .. (player.name or "Unknown") .. " has permanently died: " .. causeOfDeath)
    
    -- Calculate final statistics
    local deathStats = self:calculateDeathStats(player, causeOfDeath)
    
    -- Drop equipment (non-soulbound items)
    self:dropPlayerEquipment(player)
    
    -- Mark player as permanently dead
    player.isDead = true
    player.isAlive = false
    player.deathStats = deathStats
    
    -- Trigger death screen
    if player.id == "local_player" then -- Main player
        self:showDeathScreen(player, deathStats)
    end
    
    return deathStats
end

-- Calculate death statistics
function DeathSystem:calculateDeathStats(player, causeOfDeath)
    local stats = {
        level = player.level or 1,
        experience = player.experience or 0,
        kills = player.kills or 0,
        timeAlive = player.timeAlive or 0,
        causeOfDeath = causeOfDeath,
        className = player.shipClass and player.shipClass.name or "Unknown",
        fame = self:calculateFame(player),
        timestamp = os.time()
    }
    
    return stats
end

-- Calculate fame for the character
function DeathSystem:calculateFame(player)
    local baseFame = (player.level or 1) * 20
    local bonusFame = 0
    
    -- Bonus fame for achievements
    if player.level and player.level >= 20 then
        bonusFame = bonusFame + 200 -- First level 20
    end
    
    if player.kills and player.kills >= 100 then
        bonusFame = bonusFame + 100 -- 100 kills
    end
    
    if player.timeAlive and player.timeAlive >= 3600 then -- 1 hour
        bonusFame = bonusFame + 150 -- Survival bonus
    end
    
    return baseFame + bonusFame
end

-- Drop player equipment on death
function DeathSystem:dropPlayerEquipment(player)
    local drops = {}
    
    -- Check each equipment slot
    local equipmentSlots = {"weapon1", "weapon2", "weapon3", "shield", "engine"}
    
    for _, slot in ipairs(equipmentSlots) do
        local item = player[slot]
        if item and not item.soulbound then
            table.insert(drops, {
                item = item,
                x = player.x + math.random(-50, 50),
                y = player.y + math.random(-50, 50)
            })
        end
    end
    
    -- Create loot bags for dropped items
    player.deathDrops = drops
    
    print("Dropped " .. #drops .. " items on death")
    return drops
end

-- Trigger death warning effects
function DeathSystem:triggerDeathWarning(player)
    if not player then return end
    
    player.deathWarning = {
        startTime = love.timer.getTime(),
        duration = self.gracePeriod,
        intensity = 1.0
    }
end

-- Show death screen (to be integrated with UI)
function DeathSystem:showDeathScreen(player, deathStats)
    -- This would integrate with the game's UI system
    player.showDeathScreen = true
    player.deathScreenStats = deathStats
    
    print("=== DEATH SCREEN ===")
    print("Character: " .. (player.name or "Unknown"))
    print("Class: " .. deathStats.className)
    print("Level: " .. deathStats.level)
    print("Experience: " .. deathStats.experience)
    print("Kills: " .. deathStats.kills)
    print("Time Alive: " .. string.format("%.1f", deathStats.timeAlive) .. "s")
    print("Cause of Death: " .. deathStats.causeOfDeath)
    print("Fame Earned: " .. deathStats.fame)
    print("====================")
end

-- Check if player is in grace period
function DeathSystem:isPlayerDying(player)
    if not player or not player.id then return false end
    return self.dyingPlayers[player.id] ~= nil
end

-- Get grace time remaining for player
function DeathSystem:getGraceTimeRemaining(player)
    if not player or not player.id then return 0 end
    
    local deathState = self.dyingPlayers[player.id]
    if not deathState then return 0 end
    
    return math.max(0, deathState.graceTimeRemaining)
end

-- Draw death-related UI elements
function DeathSystem:drawDeathUI(player, x, y)
    if not player then return end
    
    -- Draw grace period countdown
    if self:isPlayerDying(player) then
        local timeRemaining = self:getGraceTimeRemaining(player)
        
        -- Death warning background
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Grace period countdown
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("DYING! " .. string.format("%.1f", timeRemaining) .. "s", 
                          x, y, 0, 2, 2)
        love.graphics.print("Find healing to survive!", x, y + 40, 0, 1.5, 1.5)
    end
    
    -- Draw saved effect
    if player.savedEffect then
        local elapsed = love.timer.getTime() - player.savedEffect.startTime
        if elapsed < player.savedEffect.duration then
            local alpha = 1.0 - (elapsed / player.savedEffect.duration)
            love.graphics.setColor(0, 1, 0, alpha)
            love.graphics.print("SAVED!", player.x - 30, player.y - 60, 0, 2, 2)
        else
            player.savedEffect = nil
        end
    end
end

-- Force immediate death (for testing or special cases)
function DeathSystem:forcePlayerDeath(player, causeOfDeath)
    if not player then return end
    
    -- Skip grace period
    return self:finalizePlayerDeath(player, causeOfDeath or "Forced death")
end

-- Clean up death system data for a player
function DeathSystem:cleanupPlayer(playerId)
    if self.dyingPlayers[playerId] then
        self.dyingPlayers[playerId] = nil
    end
end

return DeathSystem
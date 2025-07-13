-- Player Manager for handling multiple players in multiplayer
-- Manages both local and remote players

local Player = require('src.player')

local PlayerManager = {}
PlayerManager.__index = PlayerManager

function PlayerManager:new()
    local manager = setmetatable({}, PlayerManager)
    
    -- Local player (controlled by this client)
    manager.localPlayer = nil
    manager.localPlayerId = nil
    
    -- Remote players (controlled by other clients)
    manager.remotePlayers = {}
    
    -- Player registry (all players by ID)
    manager.players = {}
    
    return manager
end

function PlayerManager:setLocalPlayer(player, playerId)
    self.localPlayer = player
    self.localPlayerId = playerId
    
    if playerId then
        self.players[playerId] = player
    end
end

function PlayerManager:updateRemotePlayer(playerId, data)
    if playerId == self.localPlayerId then
        -- Don't update local player from network (client prediction)
        return
    end
    
    local remotePlayer = self.remotePlayers[playerId]
    
    if not remotePlayer then
        -- Create new remote player
        remotePlayer = Player:new(data.x or 0, data.y or 0)
        remotePlayer.isRemote = true
        remotePlayer.playerId = playerId
        self.remotePlayers[playerId] = remotePlayer
        self.players[playerId] = remotePlayer
    end
    
    -- Update remote player position and state
    if data.x then remotePlayer.x = data.x end
    if data.y then remotePlayer.y = data.y end
    if data.rotation then remotePlayer.rotation = data.rotation end
    if data.health then remotePlayer.health = data.health end
    
    -- Update last seen time for disconnection detection
    remotePlayer.lastUpdate = love.timer.getTime()
end

function PlayerManager:removeRemotePlayer(playerId)
    if self.remotePlayers[playerId] then
        self.remotePlayers[playerId] = nil
        self.players[playerId] = nil
        print("Removed remote player " .. playerId)
    end
end

function PlayerManager:updateAll(dt)
    -- Update local player
    if self.localPlayer then
        self.localPlayer:update(dt)
    end
    
    -- Update remote players (simplified - no input processing)
    for playerId, player in pairs(self.remotePlayers) do
        if player then
            -- Remote players don't process input, just update visual effects
            player:updateVisualEffects(dt)
            
            -- Check for timeout (remove disconnected players)
            if love.timer.getTime() - (player.lastUpdate or 0) > 10 then
                self:removeRemotePlayer(playerId)
            end
        end
    end
end

function PlayerManager:drawAll()
    -- Draw local player
    if self.localPlayer then
        self.localPlayer:draw()
    end
    
    -- Draw remote players with different appearance
    for playerId, player in pairs(self.remotePlayers) do
        if player then
            self:drawRemotePlayer(player)
        end
    end
end

function PlayerManager:drawRemotePlayer(player)
    love.graphics.push()
    love.graphics.translate(player.x, player.y)
    love.graphics.rotate(player.rotation or 0)
    
    -- Draw remote player's ship with different color
    love.graphics.setColor(0.8, 0.8, 0.8, 0.9) -- Semi-transparent gray
    player:drawShipShape()
    
    -- Draw outline
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(1)
    player:drawShipShapeOutline()
    
    love.graphics.pop()
    
    -- Draw player ID above ship
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("Player " .. player.playerId, player.x - 30, player.y - 35)
    
    -- Draw health bar
    local healthPercent = player.health / (player.maxHealth or 100)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', player.x - 20, player.y - 25, 40, 4)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle('fill', player.x - 20, player.y - 25, 40 * healthPercent, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', player.x - 20, player.y - 25, 40, 4)
end

function PlayerManager:getAllPlayers()
    return self.players
end

function PlayerManager:getLocalPlayer()
    return self.localPlayer
end

function PlayerManager:getRemotePlayers()
    return self.remotePlayers
end

function PlayerManager:getPlayerCount()
    local count = 0
    for _ in pairs(self.players) do
        count = count + 1
    end
    return count
end

-- Check collision with any player
function PlayerManager:checkPlayerCollisions(object)
    for playerId, player in pairs(self.players) do
        if player and player ~= object then
            local dx = object.x - player.x
            local dy = object.y - player.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < (object.radius + player.radius) then
                return player, playerId
            end
        end
    end
    return nil
end

return PlayerManager
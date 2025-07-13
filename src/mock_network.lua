-- Mock Network System for Development
-- This provides a simple local testing framework for multiplayer concepts
-- without requiring external socket libraries

local MockNetwork = {}
MockNetwork.__index = MockNetwork

-- Shared state between mock clients (simulates server)
local sharedState = {
    players = {},
    bullets = {},
    nextPlayerId = 1,
    gameTime = 0
}

function MockNetwork:new()
    local network = setmetatable({}, MockNetwork)
    
    network.connected = false
    network.clientId = nil
    network.username = "MockPlayer"
    
    -- Message types (same as real network)
    network.messageTypes = {
        CONNECT = 1,
        DISCONNECT = 2,
        PLAYER_UPDATE = 3,
        PLAYER_SHOOT = 4,
        GAME_STATE = 5,
        HEARTBEAT = 6,
        CHAT = 7
    }
    
    return network
end

function MockNetwork:connect(serverIP, serverPort, username)
    self.username = username or "MockPlayer"
    self.clientId = sharedState.nextPlayerId
    sharedState.nextPlayerId = sharedState.nextPlayerId + 1
    
    -- Add player to shared state
    sharedState.players[self.clientId] = {
        id = self.clientId,
        x = 512,
        y = 384,
        rotation = 0,
        health = 100,
        username = self.username
    }
    
    self.connected = true
    print("Mock network connected as " .. self.username .. " (ID: " .. self.clientId .. ")")
    return true
end

function MockNetwork:disconnect()
    if not self.connected then
        return
    end
    
    -- Remove player from shared state
    if sharedState.players[self.clientId] then
        sharedState.players[self.clientId] = nil
    end
    
    self.connected = false
    print("Mock network disconnected")
end

function MockNetwork:update(dt, player)
    if not self.connected or not player then
        return
    end
    
    -- Update shared state with our player
    if sharedState.players[self.clientId] then
        sharedState.players[self.clientId].x = player.x
        sharedState.players[self.clientId].y = player.y
        sharedState.players[self.clientId].rotation = player.rotation
        sharedState.players[self.clientId].health = player.health
    end
    
    -- Update game time
    sharedState.gameTime = sharedState.gameTime + dt
    
    -- Update bullets (simple movement)
    for i = #sharedState.bullets, 1, -1 do
        local bullet = sharedState.bullets[i]
        bullet.x = bullet.x + math.cos(bullet.angle) * bullet.speed * dt
        bullet.y = bullet.y + math.sin(bullet.angle) * bullet.speed * dt
        bullet.lifetime = bullet.lifetime - dt
        
        if bullet.lifetime <= 0 then
            table.remove(sharedState.bullets, i)
        end
    end
end

function MockNetwork:sendPlayerShoot(x, y, angle)
    if not self.connected then
        return
    end
    
    -- Add bullet to shared state
    local bullet = {
        id = #sharedState.bullets + 1,
        playerId = self.clientId,
        x = x,
        y = y,
        angle = angle,
        speed = 500,
        lifetime = 3.0
    }
    
    table.insert(sharedState.bullets, bullet)
end

function MockNetwork:getOtherPlayers()
    local otherPlayers = {}
    
    for playerId, playerData in pairs(sharedState.players) do
        if playerId ~= self.clientId then
            table.insert(otherPlayers, {
                id = playerData.id,
                x = playerData.x,
                y = playerData.y,
                rotation = playerData.rotation,
                health = playerData.health
            })
        end
    end
    
    return otherPlayers
end

function MockNetwork:getServerBullets()
    local bullets = {}
    
    for _, bullet in ipairs(sharedState.bullets) do
        table.insert(bullets, {
            id = bullet.id,
            x = bullet.x,
            y = bullet.y,
            angle = bullet.angle,
            playerId = bullet.playerId
        })
    end
    
    return bullets
end

function MockNetwork:isConnected()
    return self.connected
end

function MockNetwork:getClientId()
    return self.clientId
end

-- Debug function to see shared state
function MockNetwork:getSharedState()
    return sharedState
end

return MockNetwork
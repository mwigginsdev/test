-- Terminal Drift Network Client
-- Handles communication with dedicated server

local socket = require("socket")

local NetworkClient = {}
NetworkClient.__index = NetworkClient

function NetworkClient:new()
    local client = setmetatable({}, NetworkClient)
    
    -- Connection state
    client.connected = false
    client.serverIP = "localhost"
    client.serverPort = 7777
    client.clientId = nil
    
    -- Network sockets
    client.udpSocket = nil
    client.tcpSocket = nil
    
    -- Message protocol (must match server)
    client.messageTypes = {
        CONNECT = 1,
        DISCONNECT = 2,
        PLAYER_UPDATE = 3,
        PLAYER_SHOOT = 4,
        GAME_STATE = 5,
        HEARTBEAT = 6,
        CHAT = 7
    }
    
    -- Network timing
    client.lastHeartbeat = 0
    client.heartbeatInterval = 5.0 -- Send heartbeat every 5 seconds
    client.lastPlayerUpdate = 0
    client.playerUpdateRate = 1/60 -- 60 fps
    
    -- Game state from server
    client.serverPlayers = {}
    client.serverBullets = {}
    client.gameTime = 0
    
    -- Local player state for prediction
    client.localPlayer = nil
    client.pendingInputs = {}
    
    return client
end

function NetworkClient:connect(serverIP, serverPort, username)
    if self.connected then
        print("Already connected to server")
        return false
    end
    
    self.serverIP = serverIP or self.serverIP
    self.serverPort = serverPort or self.serverPort
    
    -- Create UDP socket
    self.udpSocket = socket.udp()
    if not self.udpSocket then
        print("ERROR: Failed to create UDP socket")
        return false
    end
    
    self.udpSocket:settimeout(0)
    
    -- Send connection request
    local connectMessage = {
        type = self.messageTypes.CONNECT,
        username = username or "Anonymous"
    }
    
    self:sendUDPMessage(connectMessage)
    
    print("Connecting to server " .. self.serverIP .. ":" .. self.serverPort)
    return true
end

function NetworkClient:disconnect()
    if not self.connected then
        return
    end
    
    -- Send disconnect message
    local disconnectMessage = {
        type = self.messageTypes.DISCONNECT
    }
    
    self:sendUDPMessage(disconnectMessage)
    
    -- Close sockets
    if self.udpSocket then
        self.udpSocket:close()
        self.udpSocket = nil
    end
    
    if self.tcpSocket then
        self.tcpSocket:close()
        self.tcpSocket = nil
    end
    
    self.connected = false
    self.clientId = nil
    
    print("Disconnected from server")
end

function NetworkClient:update(dt, player)
    if not self.udpSocket then
        return
    end
    
    -- Process incoming messages
    self:processMessages()
    
    -- Send player updates
    if self.connected and player then
        self:sendPlayerUpdate(dt, player)
    end
    
    -- Send heartbeat
    self:sendHeartbeat(dt)
end

function NetworkClient:processMessages()
    while true do
        local data, ip, port = self.udpSocket:receivefrom()
        if not data then
            break
        end
        
        local success, message = pcall(self.decodeMessage, data)
        if success and message then
            self:handleMessage(message)
        end
    end
end

function NetworkClient:handleMessage(message)
    if message.type == self.messageTypes.CONNECT then
        if message.success then
            self.connected = true
            self.clientId = message.clientId
            self.gameTime = message.gameTime or 0
            print("Connected to server! Client ID: " .. self.clientId)
        else
            print("Connection rejected by server")
        end
        
    elseif message.type == self.messageTypes.GAME_STATE then
        self:handleGameState(message)
        
    elseif message.type == self.messageTypes.PLAYER_UPDATE then
        if message.correction then
            self:handleServerCorrection(message)
        end
    end
end

function NetworkClient:handleGameState(message)
    self.gameTime = message.gameTime or self.gameTime
    
    -- Update server player states
    self.serverPlayers = {}
    if message.players then
        for _, playerData in ipairs(message.players) do
            self.serverPlayers[playerData.id] = {
                id = playerData.id,
                x = playerData.x,
                y = playerData.y,
                rotation = playerData.rotation,
                health = playerData.health
            }
        end
    end
    
    -- Update server bullet states
    self.serverBullets = {}
    if message.bullets then
        for _, bulletData in ipairs(message.bullets) do
            table.insert(self.serverBullets, {
                id = bulletData.id,
                x = bulletData.x,
                y = bulletData.y,
                angle = bulletData.angle,
                playerId = bulletData.playerId
            })
        end
    end
end

function NetworkClient:handleServerCorrection(message)
    -- Server has corrected our position due to invalid movement
    if self.localPlayer then
        self.localPlayer.x = message.x
        self.localPlayer.y = message.y
        self.localPlayer.rotation = message.rotation
        print("Position corrected by server")
    end
end

function NetworkClient:sendPlayerUpdate(dt, player)
    if not self.connected then
        return
    end
    
    self.lastPlayerUpdate = self.lastPlayerUpdate + dt
    
    if self.lastPlayerUpdate >= self.playerUpdateRate then
        self.lastPlayerUpdate = 0
        
        local updateMessage = {
            type = self.messageTypes.PLAYER_UPDATE,
            x = player.x,
            y = player.y,
            rotation = player.rotation
        }
        
        self:sendUDPMessage(updateMessage)
        
        -- Store local player reference for prediction
        self.localPlayer = player
    end
end

function NetworkClient:sendPlayerShoot(x, y, angle)
    if not self.connected then
        return
    end
    
    local shootMessage = {
        type = self.messageTypes.PLAYER_SHOOT,
        x = x,
        y = y,
        angle = angle
    }
    
    self:sendUDPMessage(shootMessage)
end

function NetworkClient:sendHeartbeat(dt)
    if not self.connected then
        return
    end
    
    self.lastHeartbeat = self.lastHeartbeat + dt
    
    if self.lastHeartbeat >= self.heartbeatInterval then
        self.lastHeartbeat = 0
        
        local heartbeatMessage = {
            type = self.messageTypes.HEARTBEAT
        }
        
        self:sendUDPMessage(heartbeatMessage)
    end
end

function NetworkClient:sendUDPMessage(message)
    if not self.udpSocket then
        return
    end
    
    local data = self:encodeMessage(message)
    if data then
        self.udpSocket:sendto(data, self.serverIP, self.serverPort)
    end
end

function NetworkClient:encodeMessage(message)
    -- Simple encoding - matches server implementation
    local success, result = pcall(function()
        local data = ""
        for k, v in pairs(message) do
            data = data .. k .. ":" .. tostring(v) .. ";"
        end
        return data
    end)
    
    return success and result or nil
end

function NetworkClient:decodeMessage(data)
    -- Simple decoding - matches server implementation
    local message = {}
    
    for pair in data:gmatch("([^;]+)") do
        local key, value = pair:match("([^:]+):(.+)")
        if key and value then
            -- Try to convert to number
            local numValue = tonumber(value)
            if numValue then
                message[key] = numValue
            else
                message[key] = value
            end
        end
    end
    
    return message
end

-- Get other players for rendering
function NetworkClient:getOtherPlayers()
    local otherPlayers = {}
    
    for playerId, playerData in pairs(self.serverPlayers) do
        if playerId ~= self.clientId then
            table.insert(otherPlayers, playerData)
        end
    end
    
    return otherPlayers
end

-- Get server bullets for rendering
function NetworkClient:getServerBullets()
    return self.serverBullets
end

function NetworkClient:isConnected()
    return self.connected
end

function NetworkClient:getClientId()
    return self.clientId
end

return NetworkClient
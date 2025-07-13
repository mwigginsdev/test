-- Terminal Drift Dedicated Server
-- Phase 1: Basic Server Framework with UDP networking

local socket = require("socket")

local Server = {}
Server.__index = Server

function Server:new(port)
    local server = setmetatable({}, Server)
    
    -- Server configuration
    server.port = port or 7777
    server.running = false
    server.tickRate = 60 -- 60 fps server tick rate
    server.tickDuration = 1 / server.tickRate
    
    -- Network sockets
    server.udpSocket = nil
    server.tcpSocket = nil
    
    -- Connected clients
    server.clients = {}
    server.nextClientId = 1
    
    -- Game state
    server.gameTime = 0
    server.lastTick = socket.gettime()
    
    -- Player entities (server-authoritative)
    server.players = {}
    server.bullets = {}
    server.enemies = {}
    
    -- Network protocol
    server.messageTypes = {
        CONNECT = 1,
        DISCONNECT = 2,
        PLAYER_UPDATE = 3,
        PLAYER_SHOOT = 4,
        GAME_STATE = 5,
        HEARTBEAT = 6,
        CHAT = 7
    }
    
    print("Terminal Drift Server initialized on port " .. server.port)
    return server
end

function Server:start()
    if self.running then
        print("Server is already running")
        return false
    end
    
    -- Create UDP socket for real-time game data
    self.udpSocket = socket.udp()
    if not self.udpSocket then
        print("ERROR: Failed to create UDP socket")
        return false
    end
    
    local success, err = self.udpSocket:setsockname("*", self.port)
    if not success then
        print("ERROR: Failed to bind UDP socket: " .. (err or "unknown error"))
        return false
    end
    
    -- Set UDP socket to non-blocking
    self.udpSocket:settimeout(0)
    
    -- Create TCP socket for reliable data
    self.tcpSocket = socket.tcp()
    if not self.tcpSocket then
        print("ERROR: Failed to create TCP socket")
        return false
    end
    
    local success, err = self.tcpSocket:bind("*", self.port + 1)
    if not success then
        print("ERROR: Failed to bind TCP socket: " .. (err or "unknown error"))
        return false
    end
    
    self.tcpSocket:listen(32)
    self.tcpSocket:settimeout(0)
    
    self.running = true
    self.lastTick = socket.gettime()
    
    print("Server started successfully!")
    print("UDP listening on port " .. self.port)
    print("TCP listening on port " .. (self.port + 1))
    
    return true
end

function Server:stop()
    if not self.running then
        return
    end
    
    self.running = false
    
    -- Disconnect all clients
    for clientId, client in pairs(self.clients) do
        self:disconnectClient(clientId, "Server shutdown")
    end
    
    -- Close sockets
    if self.udpSocket then
        self.udpSocket:close()
    end
    if self.tcpSocket then
        self.tcpSocket:close()
    end
    
    print("Server stopped")
end

function Server:update()
    if not self.running then
        return
    end
    
    local currentTime = socket.gettime()
    local deltaTime = currentTime - self.lastTick
    
    -- Update server at fixed tick rate
    if deltaTime >= self.tickDuration then
        self.gameTime = self.gameTime + deltaTime
        self.lastTick = currentTime
        
        -- Process network messages
        self:processUDPMessages()
        self:processTCPConnections()
        
        -- Update game logic
        self:updateGameState(deltaTime)
        
        -- Send game state to clients
        self:broadcastGameState()
        
        -- Check for disconnected clients
        self:checkClientTimeouts()
    end
end

function Server:processUDPMessages()
    while true do
        local data, ip, port = self.udpSocket:receivefrom()
        if not data then
            break
        end
        
        local success, message = pcall(self.decodeMessage, data)
        if success and message then
            self:handleUDPMessage(message, ip, port)
        end
    end
end

function Server:processTCPConnections()
    -- Accept new TCP connections
    local client = self.tcpSocket:accept()
    if client then
        client:settimeout(0)
        local ip, port = client:getpeername()
        print("New TCP connection from " .. ip .. ":" .. port)
        
        -- Add to pending connections (will be activated on UDP connect)
        -- TCP is used for reliable data like chat, not for initial connection
    end
end

function Server:handleUDPMessage(message, ip, port)
    local clientKey = ip .. ":" .. port
    
    if message.type == self.messageTypes.CONNECT then
        self:handleClientConnect(message, ip, port)
    elseif message.type == self.messageTypes.DISCONNECT then
        self:handleClientDisconnect(message, ip, port)
    elseif message.type == self.messageTypes.PLAYER_UPDATE then
        self:handlePlayerUpdate(message, ip, port)
    elseif message.type == self.messageTypes.PLAYER_SHOOT then
        self:handlePlayerShoot(message, ip, port)
    elseif message.type == self.messageTypes.HEARTBEAT then
        self:handleHeartbeat(message, ip, port)
    end
end

function Server:handleClientConnect(message, ip, port)
    local clientKey = ip .. ":" .. port
    
    if self.clients[clientKey] then
        print("Client " .. clientKey .. " already connected")
        return
    end
    
    local clientId = self.nextClientId
    self.nextClientId = self.nextClientId + 1
    
    local client = {
        id = clientId,
        ip = ip,
        port = port,
        key = clientKey,
        username = message.username or ("Player" .. clientId),
        lastHeartbeat = socket.gettime(),
        connected = true
    }
    
    self.clients[clientKey] = client
    
    -- Create player entity
    local player = {
        id = clientId,
        clientKey = clientKey,
        x = 512, -- Spawn in center
        y = 384,
        rotation = 0,
        health = 100,
        maxHealth = 100,
        lastUpdate = socket.gettime()
    }
    
    self.players[clientId] = player
    
    print("Client connected: " .. client.username .. " (" .. clientKey .. ")")
    
    -- Send connection confirmation
    local response = {
        type = self.messageTypes.CONNECT,
        success = true,
        clientId = clientId,
        gameTime = self.gameTime
    }
    
    self:sendUDPMessage(response, ip, port)
end

function Server:handleClientDisconnect(message, ip, port)
    local clientKey = ip .. ":" .. port
    self:disconnectClient(clientKey, "Client requested disconnect")
end

function Server:handlePlayerUpdate(message, ip, port)
    local clientKey = ip .. ":" .. port
    local client = self.clients[clientKey]
    
    if not client then
        return
    end
    
    local player = self.players[client.id]
    if not player then
        return
    end
    
    -- Server-side validation (basic anti-cheat)
    local maxSpeed = 300 -- pixels per second
    local timeDelta = socket.gettime() - player.lastUpdate
    local maxDistance = maxSpeed * timeDelta
    
    local dx = message.x - player.x
    local dy = message.y - player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- If movement is too fast, reject or correct
    if distance > maxDistance + 50 then -- Allow some tolerance for lag
        print("Rejecting invalid movement from " .. client.username)
        -- Send correction back to client
        local correction = {
            type = self.messageTypes.PLAYER_UPDATE,
            x = player.x,
            y = player.y,
            rotation = player.rotation,
            correction = true
        }
        self:sendUDPMessage(correction, ip, port)
        return
    end
    
    -- Update player position
    player.x = message.x
    player.y = message.y
    player.rotation = message.rotation or player.rotation
    player.lastUpdate = socket.gettime()
    
    -- Update client heartbeat
    client.lastHeartbeat = socket.gettime()
end

function Server:handlePlayerShoot(message, ip, port)
    local clientKey = ip .. ":" .. port
    local client = self.clients[clientKey]
    
    if not client then
        return
    end
    
    local player = self.players[client.id]
    if not player then
        return
    end
    
    -- Create bullet entity (server-authoritative)
    local bullet = {
        id = #self.bullets + 1,
        playerId = client.id,
        x = message.x or player.x,
        y = message.y or player.y,
        angle = message.angle,
        speed = 500,
        damage = 25,
        lifetime = 3.0,
        createdAt = socket.gettime()
    }
    
    table.insert(self.bullets, bullet)
    
    -- Update client heartbeat
    client.lastHeartbeat = socket.gettime()
end

function Server:handleHeartbeat(message, ip, port)
    local clientKey = ip .. ":" .. port
    local client = self.clients[clientKey]
    
    if client then
        client.lastHeartbeat = socket.gettime()
    end
end

function Server:updateGameState(deltaTime)
    -- Update bullets
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        
        -- Move bullet
        bullet.x = bullet.x + math.cos(bullet.angle) * bullet.speed * deltaTime
        bullet.y = bullet.y + math.sin(bullet.angle) * bullet.speed * deltaTime
        
        -- Check lifetime
        if socket.gettime() - bullet.createdAt > bullet.lifetime then
            table.remove(self.bullets, i)
        end
    end
end

function Server:broadcastGameState()
    if #self.clients == 0 then
        return
    end
    
    -- Prepare game state message
    local gameState = {
        type = self.messageTypes.GAME_STATE,
        gameTime = self.gameTime,
        players = {},
        bullets = {}
    }
    
    -- Add player data
    for clientId, player in pairs(self.players) do
        table.insert(gameState.players, {
            id = player.id,
            x = player.x,
            y = player.y,
            rotation = player.rotation,
            health = player.health
        })
    end
    
    -- Add bullet data
    for _, bullet in ipairs(self.bullets) do
        table.insert(gameState.bullets, {
            id = bullet.id,
            x = bullet.x,
            y = bullet.y,
            angle = bullet.angle,
            playerId = bullet.playerId
        })
    end
    
    -- Send to all connected clients
    for _, client in pairs(self.clients) do
        if client.connected then
            self:sendUDPMessage(gameState, client.ip, client.port)
        end
    end
end

function Server:checkClientTimeouts()
    local currentTime = socket.gettime()
    local timeoutDuration = 30 -- 30 seconds
    
    for clientKey, client in pairs(self.clients) do
        if currentTime - client.lastHeartbeat > timeoutDuration then
            self:disconnectClient(clientKey, "Timeout")
        end
    end
end

function Server:disconnectClient(clientKey, reason)
    local client = self.clients[clientKey]
    if not client then
        return
    end
    
    print("Client disconnected: " .. client.username .. " (" .. reason .. ")")
    
    -- Remove player entity
    if self.players[client.id] then
        self.players[client.id] = nil
    end
    
    -- Remove client
    self.clients[clientKey] = nil
end

function Server:sendUDPMessage(message, ip, port)
    local data = self:encodeMessage(message)
    if data then
        self.udpSocket:sendto(data, ip, port)
    end
end

function Server:encodeMessage(message)
    -- Simple encoding - in production use proper binary protocol
    local success, result = pcall(function()
        local data = ""
        for k, v in pairs(message) do
            data = data .. k .. ":" .. tostring(v) .. ";"
        end
        return data
    end)
    
    return success and result or nil
end

function Server:decodeMessage(data)
    -- Simple decoding - in production use proper binary protocol  
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

-- Server main loop
function Server:run()
    if not self:start() then
        return 1
    end
    
    print("Server running... Press Ctrl+C to stop")
    
    -- Install signal handler for graceful shutdown
    local function shutdown()
        self:stop()
        os.exit(0)
    end
    
    -- Main server loop
    while self.running do
        self:update()
        socket.sleep(0.001) -- Small sleep to prevent 100% CPU usage
    end
    
    return 0
end

return Server
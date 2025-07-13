-- Nexus Hub World
-- Safe area where players can gather, chat, and access portals to combat areas

local Nexus = {}
Nexus.__index = Nexus

function Nexus:new(width, height)
    local nexus = setmetatable({}, Nexus)
    
    nexus.width = width
    nexus.height = height
    
    -- Safe zone boundaries
    nexus.safeZone = {
        x = width / 4,
        y = height / 4,
        width = width / 2,
        height = height / 2
    }
    
    -- Portals to combat areas
    nexus.portals = {}
    nexus:createPortals()
    
    -- Chat system
    nexus.chatMessages = {}
    nexus.maxChatMessages = 20
    nexus.chatInput = ""
    nexus.chatActive = false
    
    -- Player list display
    nexus.showPlayerList = true
    
    return nexus
end

function Nexus:createPortals()
    -- Create portals around the safe zone
    local portalTypes = {
        {name = "ASTEROID FIELD", difficulty = 1, color = {0.7, 0.7, 0.7}},
        {name = "PIRATE SECTOR", difficulty = 2, color = {0.9, 0.3, 0.3}},
        {name = "ALIEN ZONE", difficulty = 3, color = {0.3, 0.9, 0.3}},
        {name = "DEEP SPACE", difficulty = 4, color = {0.3, 0.3, 0.9}}
    }
    
    local centerX = self.width / 2
    local centerY = self.height / 2
    local radius = 200
    
    for i, portalType in ipairs(portalTypes) do
        local angle = (i - 1) * (2 * math.pi / #portalTypes)
        local portal = {
            x = centerX + math.cos(angle) * radius,
            y = centerY + math.sin(angle) * radius,
            radius = 30,
            name = portalType.name,
            difficulty = portalType.difficulty,
            color = portalType.color,
            active = true,
            particles = {}
        }
        
        table.insert(self.portals, portal)
    end
end

function Nexus:update(dt, player, playerManager)
    -- Players are invulnerable in nexus - no damage processing
    
    -- Update portal effects
    for _, portal in ipairs(self.portals) do
        self:updatePortalEffects(portal, dt)
    end
    
    -- Check portal interactions
    if player then
        self:checkPortalInteractions(player)
    end
end

function Nexus:updatePortalEffects(portal, dt)
    -- Create swirling portal particles
    if #portal.particles < 20 then
        local angle = love.timer.getTime() * 2 + math.random() * math.pi * 2
        local distance = math.random(5, portal.radius - 5)
        
        table.insert(portal.particles, {
            x = portal.x + math.cos(angle) * distance,
            y = portal.y + math.sin(angle) * distance,
            angle = angle,
            distance = distance,
            life = math.random(2, 4),
            maxLife = 4
        })
    end
    
    -- Update existing particles
    for i = #portal.particles, 1, -1 do
        local particle = portal.particles[i]
        particle.life = particle.life - dt
        particle.angle = particle.angle + dt * 2
        
        -- Spiral effect
        particle.distance = particle.distance * (1 - dt * 0.3)
        particle.x = portal.x + math.cos(particle.angle) * particle.distance
        particle.y = portal.y + math.sin(particle.angle) * particle.distance
        
        if particle.life <= 0 then
            table.remove(portal.particles, i)
        end
    end
end

function Nexus:checkPortalInteractions(player)
    for _, portal in ipairs(self.portals) do
        if portal.active then
            local dx = player.x - portal.x
            local dy = player.y - portal.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < portal.radius + player.radius then
                portal.nearPlayer = true
            else
                portal.nearPlayer = false
            end
        end
    end
end

function Nexus:usePortal(portalIndex)
    local portal = self.portals[portalIndex]
    if portal and portal.active then
        print("Entering " .. portal.name .. " (Difficulty: " .. portal.difficulty .. ")")
        return portal
    end
    return nil
end

function Nexus:addChatMessage(message, playerName)
    local chatMessage = {
        text = message,
        player = playerName or "Unknown",
        timestamp = love.timer.getTime(),
        color = {0.8, 1, 0.8}
    }
    
    table.insert(self.chatMessages, chatMessage)
    
    -- Remove old messages
    while #self.chatMessages > self.maxChatMessages do
        table.remove(self.chatMessages, 1)
    end
end

function Nexus:startChatInput()
    self.chatActive = true
    self.chatInput = ""
end

function Nexus:endChatInput()
    self.chatActive = false
    local message = self.chatInput
    self.chatInput = ""
    return message
end

function Nexus:addChatCharacter(char)
    if self.chatActive and #self.chatInput < 100 then
        self.chatInput = self.chatInput .. char
    end
end

function Nexus:removeChatCharacter()
    if self.chatActive and #self.chatInput > 0 then
        self.chatInput = self.chatInput:sub(1, -2)
    end
end

function Nexus:draw(camera, playerManager)
    -- Draw safe zone boundary
    love.graphics.setColor(0, 1, 1, 0.3)
    love.graphics.rectangle('line', self.safeZone.x, self.safeZone.y, self.safeZone.width, self.safeZone.height)
    
    -- Draw "SAFE ZONE" text
    love.graphics.setColor(0, 1, 1, 0.8)
    love.graphics.print("SAFE ZONE - NO COMBAT", self.safeZone.x + 10, self.safeZone.y - 25, 0, 1.5, 1.5)
    
    -- Draw portals
    for i, portal in ipairs(self.portals) do
        self:drawPortal(portal, i)
    end
    
    -- Draw nexus center
    love.graphics.setColor(1, 1, 0, 0.5)
    love.graphics.circle('fill', self.width / 2, self.height / 2, 50)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('line', self.width / 2, self.height / 2, 50)
    
    -- Draw nexus label
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("NEXUS", self.width / 2 - 25, self.height / 2 - 8, 0, 1.5, 1.5)
end

function Nexus:drawPortal(portal, index)
    -- Draw portal base
    love.graphics.setColor(portal.color[1], portal.color[2], portal.color[3], 0.6)
    love.graphics.circle('fill', portal.x, portal.y, portal.radius)
    
    -- Draw portal particles
    for _, particle in ipairs(portal.particles) do
        local alpha = particle.life / particle.maxLife
        love.graphics.setColor(portal.color[1], portal.color[2], portal.color[3], alpha)
        love.graphics.circle('fill', particle.x, particle.y, 2)
    end
    
    -- Draw portal outline
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('line', portal.x, portal.y, portal.radius)
    
    -- Draw portal name
    love.graphics.setColor(portal.color)
    love.graphics.print(portal.name, portal.x - 40, portal.y - portal.radius - 20)
    love.graphics.print("Difficulty: " .. portal.difficulty, portal.x - 30, portal.y - portal.radius - 5)
    
    -- Draw interaction hint
    if portal.nearPlayer then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("[ENTER] TO USE", portal.x - 35, portal.y + portal.radius + 5)
    end
    
    -- Draw portal number
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(index), portal.x - 5, portal.y - 5, 0, 1.5, 1.5)
end

function Nexus:drawUI()
    -- Draw chat area
    self:drawChat()
    
    -- Draw controls
    self:drawControls()
end

function Nexus:drawChat()
    local chatX = 10
    local chatY = love.graphics.getHeight() - 200
    local chatWidth = 400
    local chatHeight = 150
    
    -- Chat background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', chatX, chatY, chatWidth, chatHeight)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle('line', chatX, chatY, chatWidth, chatHeight)
    
    -- Chat messages
    local messageY = chatY + chatHeight - 40
    for i = #self.chatMessages, math.max(1, #self.chatMessages - 5), -1 do
        local msg = self.chatMessages[i]
        love.graphics.setColor(msg.color)
        love.graphics.print(msg.player .. ": " .. msg.text, chatX + 5, messageY)
        messageY = messageY - 15
    end
    
    -- Chat input
    if self.chatActive then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("> " .. self.chatInput .. "_", chatX + 5, chatY + chatHeight - 20)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Press T to chat", chatX + 5, chatY + chatHeight - 20)
    end
end

function Nexus:drawControls()
    local controlsX = love.graphics.getWidth() - 300
    local controlsY = love.graphics.getHeight() - 150
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("NEXUS CONTROLS:", controlsX, controlsY)
    love.graphics.print("T - Chat", controlsX, controlsY + 20)
    love.graphics.print("1-4 - Use Portal", controlsX, controlsY + 40)
    love.graphics.print("TAB - Player List", controlsX, controlsY + 60)
    love.graphics.print("ESC - Leave Nexus", controlsX, controlsY + 80)
end

function Nexus:keypressed(key)
    if self.chatActive then
        if key == "return" then
            local message = self:endChatInput()
            if #message > 0 then
                return "chat", message
            end
        elseif key == "escape" then
            self:endChatInput()
        elseif key == "backspace" then
            self:removeChatCharacter()
        end
    else
        if key == "t" then
            self:startChatInput()
        elseif key == "1" or key == "2" or key == "3" or key == "4" then
            local portalIndex = tonumber(key)
            local portal = self:usePortal(portalIndex)
            if portal then
                return "portal", portal
            end
        elseif key == "escape" then
            return "leave_nexus"
        end
    end
    
    return nil
end

function Nexus:textinput(text)
    if self.chatActive then
        self:addChatCharacter(text)
    end
end

function Nexus:isInSafeZone(x, y)
    return x >= self.safeZone.x and x <= self.safeZone.x + self.safeZone.width and
           y >= self.safeZone.y and y <= self.safeZone.y + self.safeZone.height
end

return Nexus
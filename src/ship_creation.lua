-- Ship creation screen

local ShipCreation = {}
ShipCreation.__index = ShipCreation

function ShipCreation:new()
    local creation = setmetatable({}, ShipCreation)
    
    creation.isVisible = false
    creation.selectedStyle = 1
    creation.shipName = "NEW SHIP"
    creation.inputMode = false -- true when typing name
    creation.shipStyles = {
        {
            name = "FIGHTER",
            description = "Balanced combat vessel",
            shape = "triangle",
            color = {0.2, 0.8, 1.0},
            stats = {speed = 300, health = 100, fireRate = 0.15}
        },
        {
            name = "INTERCEPTOR", 
            description = "Fast and agile",
            shape = "arrow",
            color = {1.0, 0.3, 0.3},
            stats = {speed = 400, health = 80, fireRate = 0.12}
        },
        {
            name = "GUNSHIP",
            description = "Heavy weapons platform",
            shape = "pentagon",
            color = {1.0, 0.8, 0.2},
            stats = {speed = 250, health = 140, fireRate = 0.2}
        },
        {
            name = "SCOUT",
            description = "Exploration specialist",
            shape = "diamond",
            color = {0.3, 1.0, 0.3},
            stats = {speed = 350, health = 90, fireRate = 0.18}
        }
    }
    
    return creation
end

function ShipCreation:show(slotNumber)
    self.isVisible = true
    self.slotNumber = slotNumber
    self.selectedStyle = 1
    self.shipName = "SHIP " .. slotNumber
    self.inputMode = false
end

function ShipCreation:hide()
    self.isVisible = false
end

function ShipCreation:keypressed(key)
    if not self.isVisible then return end
    
    if self.inputMode then
        if key == "return" then
            self.inputMode = false
        elseif key == "escape" then
            self.inputMode = false
        elseif key == "backspace" then
            self.shipName = self.shipName:sub(1, -2)
        elseif string.len(key) == 1 and string.len(self.shipName) < 20 then
            self.shipName = self.shipName .. string.upper(key)
        end
    else
        if key == "left" then
            self.selectedStyle = math.max(1, self.selectedStyle - 1)
        elseif key == "right" then
            self.selectedStyle = math.min(#self.shipStyles, self.selectedStyle + 1)
        elseif key == "return" or key == "space" then
            return self:createShip()
        elseif key == "n" then
            self.inputMode = true
        elseif key == "escape" then
            return "cancel"
        end
    end
    
    return nil
end

function ShipCreation:createShip()
    local style = self.shipStyles[self.selectedStyle]
    local newShip = {
        name = self.shipName,
        style = self.selectedStyle,
        level = 1,
        credits = 1000,
        exists = true,
        health = style.stats.health,
        maxHealth = style.stats.health,
        speed = style.stats.speed,
        fireRate = style.stats.fireRate,
        experience = 0,
        experienceToNext = 100,
        color = style.color,
        shape = style.shape
    }
    
    return "create", newShip
end

function ShipCreation:draw()
    if not self.isVisible then return end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.15, 0.95)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Title
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("CREATE NEW SHIP - SLOT " .. self.slotNumber, width/2 - 200, 50, 0, 2, 2)
    
    -- Ship name input
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHIP NAME:", 100, 120, 0, 1.5, 1.5)
    
    local nameColor = self.inputMode and {1, 1, 0} or {0.8, 0.8, 0.8}
    love.graphics.setColor(nameColor)
    love.graphics.rectangle("line", 250, 115, 300, 30)
    love.graphics.print(self.shipName, 260, 122, 0, 1.2, 1.2)
    
    if self.inputMode then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("_", 260 + love.graphics.getFont():getWidth(self.shipName) * 1.2, 122, 0, 1.2, 1.2)
    end
    
    -- Ship styles
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHIP CLASS:", 100, 180, 0, 1.5, 1.5)
    
    local startX = 150
    local styleWidth = 200
    for i, style in ipairs(self.shipStyles) do
        local x = startX + (i-1) * (styleWidth + 20)
        local y = 220
        local isSelected = (i == self.selectedStyle)
        
        -- Selection highlight
        if isSelected then
            love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
            love.graphics.rectangle("fill", x - 10, y - 10, styleWidth, 200)
        end
        
        -- Border
        love.graphics.setColor(isSelected and {0, 1, 1} or {0.5, 0.5, 0.5})
        love.graphics.rectangle("line", x - 10, y - 10, styleWidth, 200)
        
        -- Ship preview
        love.graphics.setColor(style.color)
        self:drawShipShape(x + styleWidth/2, y + 50, style.shape, 30)
        
        -- Style name
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(style.name, x, y + 80, 0, 1.2, 1.2)
        
        -- Description
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(style.description, x, y + 105, 0, 0.9, 0.9)
        
        -- Stats
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("SPD: " .. style.stats.speed, x, y + 130, 0, 0.8, 0.8)
        love.graphics.print("HP: " .. style.stats.health, x, y + 145, 0, 0.8, 0.8)
        love.graphics.print("FR: " .. string.format("%.2f", style.stats.fireRate), x, y + 160, 0, 0.8, 0.8)
    end
    
    -- Controls
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("←→ Select Class   N Edit Name   ENTER Create   ESC Cancel", width/2 - 250, height - 80, 0, 1, 1)
    
    if self.inputMode then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Type ship name, ENTER to confirm", width/2 - 120, height - 50, 0, 1, 1)
    end
end

function ShipCreation:drawShipShape(x, y, shape, size)
    if shape == "triangle" then
        love.graphics.polygon("fill", x, y - size, x - size*0.7, y + size*0.7, x + size*0.7, y + size*0.7)
    elseif shape == "arrow" then
        love.graphics.polygon("fill", x, y - size, x - size*0.4, y, x - size*0.7, y + size, x + size*0.7, y + size, x + size*0.4, y)
    elseif shape == "pentagon" then
        local points = {}
        for i = 0, 4 do
            local angle = (i / 5) * 2 * math.pi - math.pi/2
            table.insert(points, x + math.cos(angle) * size)
            table.insert(points, y + math.sin(angle) * size)
        end
        love.graphics.polygon("fill", points)
    elseif shape == "diamond" then
        love.graphics.polygon("fill", x, y - size, x + size*0.7, y, x, y + size, x - size*0.7, y)
    end
end

return ShipCreation
-- Ship creation screen

local ShipClassManager = require('src.ship_class_manager')

local ShipCreation = {}
ShipCreation.__index = ShipCreation

function ShipCreation:new()
    local creation = setmetatable({}, ShipCreation)
    
    creation.isVisible = false
    creation.selectedClass = 1
    creation.shipName = "NEW SHIP"
    creation.inputMode = false -- true when typing name
    creation.playerLevel = 1 -- For determining unlocked classes
    
    -- Initialize ship class manager
    creation.classManager = ShipClassManager:new()
    
    -- Get available classes
    creation.availableClasses = creation.classManager:getAvailableClasses(creation.playerLevel)
    
    return creation
end

function ShipCreation:show(slotNumber)
    self.isVisible = true
    self.slotNumber = slotNumber
    self.selectedClass = 1
    self.shipName = "SHIP " .. slotNumber
    self.inputMode = false
    
    -- Refresh available classes
    self.availableClasses = self.classManager:getAvailableClasses(self.playerLevel)
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
            self.selectedClass = math.max(1, self.selectedClass - 1)
        elseif key == "right" then
            self.selectedClass = math.min(#self.availableClasses, self.selectedClass + 1)
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
    local selectedClassData = self.availableClasses[self.selectedClass]
    
    if not selectedClassData.unlocked then
        print("Class not unlocked!")
        return nil
    end
    
    local classInstance = selectedClassData.class
    local newShip = {
        name = self.shipName,
        classType = selectedClassData.type,
        level = 1,
        credits = 1000,
        exists = true,
        health = classInstance.baseStats.health,
        maxHealth = classInstance.baseStats.maxHealth,
        speed = classInstance.baseStats.speed,
        fireRate = classInstance.baseStats.fireRate,
        experience = 0,
        experienceToNext = 100,
        color = classInstance.shipColor,
        shape = classInstance.shipShape
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
    
    -- Ship classes
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("SHIP CLASS:", 100, 180, 0, 1.5, 1.5)
    
    local startX = 150
    local classWidth = 180
    for i, classData in ipairs(self.availableClasses) do
        local x = startX + (i-1) * (classWidth + 15)
        local y = 220
        local isSelected = (i == self.selectedClass)
        local isUnlocked = classData.unlocked
        
        -- Selection highlight
        if isSelected then
            love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
            love.graphics.rectangle("fill", x - 10, y - 10, classWidth, 200)
        end
        
        -- Border (different color for locked classes)
        local borderColor = isUnlocked and {1, 1, 1} or {0.5, 0.5, 0.5}
        love.graphics.setColor(borderColor)
        love.graphics.rectangle("line", x - 10, y - 10, classWidth, 200)
        
        -- Ship class preview
        local class = classData.class
        if class then
            love.graphics.setColor(class.shipColor)
            self:drawShipShape(x + classWidth/2, y + 50, class.shipShape, 25)
        end
        
        -- Class name
        local nameColor = isUnlocked and {1, 1, 1} or {0.5, 0.5, 0.5}
        love.graphics.setColor(nameColor)
        love.graphics.print(class and class.name or "UNKNOWN", x, y + 80, 0, 1.1, 1.1)
        
        -- Lock indicator
        if not isUnlocked then
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.print("LOCKED", x, y + 100, 0, 0.9, 0.9)
            love.graphics.print("Req Lv " .. (classData.requiresLevel or 1), x, y + 115, 0, 0.8, 0.8)
        else
            -- Description
            love.graphics.setColor(0.8, 0.8, 0.8)
            local desc = class and class.description or ""
            love.graphics.printf(desc, x, y + 100, classWidth - 10, "left", 0, 0.8, 0.8)
        end
        
        -- Stats (only for unlocked classes)
        if isUnlocked and class then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("HP: " .. class.baseStats.health, x, y + 140, 0, 0.7, 0.7)
            love.graphics.print("SPD: " .. class.baseStats.speed, x, y + 155, 0, 0.7, 0.7)
            love.graphics.print("ATK: " .. class.baseStats.attack, x, y + 170, 0, 0.7, 0.7)
        end
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
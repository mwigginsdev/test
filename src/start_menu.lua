-- Start menu for the game

local StartMenu = {}
StartMenu.__index = StartMenu

function StartMenu:new()
    local menu = setmetatable({}, StartMenu)
    
    menu.isVisible = true
    menu.selectedOption = 1
    menu.options = {"NEW GAME", "LOAD SHIP", "TEST MP", "NEXUS", "SETTINGS", "EXIT"}
    menu.ships = {}
    menu.showingShipSelect = false
    menu.selectedShip = 1
    
    -- Load saved ships
    menu:loadShips()
    
    return menu
end

function StartMenu:loadShips()
    -- For now, create some default ships if none exist
    if #self.ships == 0 then
        table.insert(self.ships, {
            name = "DEFAULT FIGHTER",
            style = 1,
            level = 1,
            credits = 1000,
            exists = false
        })
    end
end

function StartMenu:saveShips()
    -- TODO: Implement actual save/load system
    -- For now, ships are temporary
end

function StartMenu:keypressed(key)
    if not self.isVisible then return end
    
    if self.showingShipSelect then
        if key == "up" then
            self.selectedShip = math.max(1, self.selectedShip - 1)
        elseif key == "down" then
            self.selectedShip = math.min(5, self.selectedShip + 1)
        elseif key == "return" or key == "space" then
            if self.selectedShip <= #self.ships and self.ships[self.selectedShip].exists then
                return "load_ship", self.ships[self.selectedShip]
            else
                return "create_ship", self.selectedShip
            end
        elseif key == "escape" then
            self.showingShipSelect = false
        end
    else
        if key == "up" then
            self.selectedOption = math.max(1, self.selectedOption - 1)
        elseif key == "down" then
            self.selectedOption = math.min(#self.options, self.selectedOption + 1)
        elseif key == "return" or key == "space" then
            return self:activateOption()
        elseif key == "escape" then
            if self.selectedOption ~= 6 then
                self.selectedOption = 6 -- EXIT is now option 6
            end
        end
    end
    
    return nil
end

function StartMenu:activateOption()
    local option = self.options[self.selectedOption]
    
    if option == "NEW GAME" then
        return "create_ship", 1
    elseif option == "LOAD SHIP" then
        self.showingShipSelect = true
        return nil
    elseif option == "TEST MP" then
        -- Create a test ship for multiplayer
        local testShip = {
            name = "TEST MP SHIP",
            style = 1,
            shape = "triangle",
            color = {0.3, 0.8, 1.0},
            level = 1,
            credits = 1000,
            health = 100,
            maxHealth = 100,
            speed = 300,
            fireRate = 0.15,
            exists = true
        }
        return "test_multiplayer", testShip
    elseif option == "NEXUS" then
        -- Create a test ship for nexus
        local nexusShip = {
            name = "NEXUS VISITOR",
            style = 1,
            shape = "triangle",
            color = {1.0, 1.0, 0.3},
            level = 1,
            credits = 1000,
            health = 100,
            maxHealth = 100,
            speed = 300,
            fireRate = 0.15,
            exists = true
        }
        return "enter_nexus", nexusShip
    elseif option == "SETTINGS" then
        return "settings"
    elseif option == "EXIT" then
        return "exit"
    end
    
    return nil
end

function StartMenu:hide()
    self.isVisible = false
end

function StartMenu:show()
    self.isVisible = true
    self.showingShipSelect = false
end

function StartMenu:draw()
    if not self.isVisible then return end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.15, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Draw some background stars
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    for i = 1, 50 do
        local x = (i * 157) % width
        local y = (i * 233) % height
        love.graphics.circle("fill", x, y, 1)
    end
    
    -- Title
    love.graphics.setColor(0, 1, 1)
    local titleText = "SCI-FI BULLET HELL"
    local titleFont = love.graphics.getFont()
    local titleWidth = titleFont:getWidth(titleText) * 4
    love.graphics.print(titleText, width/2 - titleWidth/2, height/4, 0, 4, 4)
    
    if self.showingShipSelect then
        self:drawShipSelect()
    else
        self:drawMainMenu()
    end
end

function StartMenu:drawMainMenu()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Menu options
    local startY = height/2
    for i, option in ipairs(self.options) do
        local y = startY + (i-1) * 60
        local isSelected = (i == self.selectedOption)
        
        if isSelected then
            love.graphics.setColor(0, 1, 1)
            love.graphics.print("> " .. option .. " <", width/2 - 100, y, 0, 2, 2)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(option, width/2 - 80, y, 0, 2, 2)
        end
    end
    
    -- Controls
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("↑↓ Navigate   ENTER Select   ESC Exit", width/2 - 150, height - 60, 0, 1, 1)
end

function StartMenu:drawShipSelect()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Title
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("SELECT SHIP", width/2 - 80, height/3, 0, 2, 2)
    
    -- Ship slots
    local startY = height/2
    for i = 1, 5 do
        local y = startY + (i-1) * 40
        local isSelected = (i == self.selectedShip)
        local ship = self.ships[i]
        
        if isSelected then
            love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
            love.graphics.rectangle("fill", width/2 - 200, y - 5, 400, 30)
        end
        
        if ship and ship.exists then
            love.graphics.setColor(0, 1, 0)
            love.graphics.print(string.format("SLOT %d: %s (LV%d, %d cred)", i, ship.name, ship.level, ship.credits), width/2 - 180, y, 0, 1.2, 1.2)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(string.format("SLOT %d: [EMPTY - CREATE NEW]", i), width/2 - 180, y, 0, 1.2, 1.2)
        end
    end
    
    -- Controls
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("↑↓ Navigate   ENTER Select   ESC Back", width/2 - 150, height - 60, 0, 1, 1)
end

return StartMenu
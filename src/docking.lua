-- Docking interface for space stations

local Docking = {}
Docking.__index = Docking

function Docking:new(game)
    local docking = setmetatable({}, Docking)
    
    docking.game = game
    docking.isVisible = false
    docking.currentStation = nil
    docking.selectedTab = 1 -- 1=services, 2=shop, 3=crew
    docking.selectedItem = 1
    docking.tabs = {"SERVICES", "SHOP", "CREW HIRE"}
    
    return docking
end

function Docking:show(station)
    self.isVisible = true
    self.currentStation = station
    self.selectedTab = 1
    self.selectedItem = 1
end

function Docking:hide()
    self.isVisible = false
    self.currentStation = nil
end

function Docking:keypressed(key)
    if not self.isVisible then return end
    
    if key == "escape" or key == "f" then
        self:hide()
    elseif key == "left" then
        self.selectedTab = math.max(1, self.selectedTab - 1)
        self.selectedItem = 1
    elseif key == "right" then
        self.selectedTab = math.min(3, self.selectedTab + 1)
        self.selectedItem = 1
    elseif key == "up" then
        local items = self:getCurrentTabItems()
        self.selectedItem = math.max(1, self.selectedItem - 1)
    elseif key == "down" then
        local items = self:getCurrentTabItems()
        self.selectedItem = math.min(#items, self.selectedItem + 1)
    elseif key == "return" or key == "space" then
        self:activateSelectedItem()
    end
end

function Docking:getCurrentTabItems()
    if not self.currentStation then return {} end
    
    if self.selectedTab == 1 then
        return self.currentStation.services
    elseif self.selectedTab == 2 then
        return self.currentStation.inventory
    elseif self.selectedTab == 3 then
        return self.currentStation.availableCrew
    end
    
    return {}
end

function Docking:activateSelectedItem()
    if not self.currentStation then return end
    
    local items = self:getCurrentTabItems()
    if self.selectedItem < 1 or self.selectedItem > #items then
        return
    end
    
    if self.selectedTab == 1 then
        -- Services
        local service = items[self.selectedItem]
        if service == "repair" then
            local cost = math.floor((self.game.player.maxHealth - self.game.player.health) * 2)
            if self.game.player.credits >= cost then
                self.game.player.credits = self.game.player.credits - cost
                self.game.player.health = self.game.player.maxHealth
                print("Ship repaired! Cost: " .. cost .. " credits")
            else
                print("Insufficient credits for repair")
            end
        end
    elseif self.selectedTab == 2 then
        -- Shop
        local success, message = self.currentStation:buyItem(self.selectedItem, self.game.player)
        print(message)
    elseif self.selectedTab == 3 then
        -- Crew hire
        local success, message = self.currentStation:hireCrew(self.selectedItem, self.game.player)
        print(message)
    end
end

function Docking:draw()
    if not self.isVisible or not self.currentStation then return end
    
    -- Background overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Main panel
    local panelWidth = 900
    local panelHeight = 650
    local panelX = (love.graphics.getWidth() - panelWidth) / 2
    local panelY = (love.graphics.getHeight() - panelHeight) / 2
    
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(self.currentStation.color)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Station header
    love.graphics.setColor(self.currentStation.color)
    love.graphics.print("DOCKED: " .. string.upper(self.currentStation.type) .. " STATION", panelX + 20, panelY + 20, 0, 2.2, 2.2)
    
    -- Player info
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("CREDITS: " .. self.game.player.credits, panelX + panelWidth - 200, panelY + 20, 0, 1.2, 1.2)
    love.graphics.print("HEALTH: " .. self.game.player.health .. "/" .. self.game.player.maxHealth, panelX + panelWidth - 200, panelY + 45, 0, 1, 1)
    
    -- Tab navigation
    local tabWidth = 250
    local tabY = panelY + 80
    for i, tab in ipairs(self.tabs) do
        local tabX = panelX + 20 + (i-1) * (tabWidth + 10)
        local isSelected = (i == self.selectedTab)
        
        if isSelected then
            love.graphics.setColor(0.2, 0.4, 0.6, 0.8)
            love.graphics.rectangle("fill", tabX, tabY, tabWidth, 30)
        end
        
        love.graphics.setColor(isSelected and {1, 1, 1} or {0.7, 0.7, 0.7})
        love.graphics.rectangle("line", tabX, tabY, tabWidth, 30)
        love.graphics.print(tab, tabX + 10, tabY + 8, 0, 1, 1)
    end
    
    -- Content area
    local contentY = panelY + 130
    local items = self:getCurrentTabItems()
    
    if self.selectedTab == 1 then
        -- Services
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("AVAILABLE SERVICES:", panelX + 20, contentY, 0, 1.2, 1.2)
        
        for i, service in ipairs(items) do
            local y = contentY + 30 + (i-1) * 30
            local isSelected = (i == self.selectedItem)
            
            if isSelected then
                love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
                love.graphics.rectangle("fill", panelX + 15, y - 2, panelWidth - 30, 25)
            end
            
            love.graphics.setColor(0.7, 1, 0.7)
            local serviceName = string.upper(service)
            love.graphics.print("• " .. serviceName, panelX + 25, y, 0, 1.1, 1.1)
            
            -- Service descriptions
            if service == "repair" then
                local cost = math.floor((self.game.player.maxHealth - self.game.player.health) * 2)
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("Cost: " .. cost .. " credits", panelX + 300, y, 0, 1, 1)
            end
        end
        
    elseif self.selectedTab == 2 then
        -- Shop
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("ITEMS FOR SALE:", panelX + 20, contentY, 0, 1.2, 1.2)
        
        for i, item in ipairs(items) do
            local y = contentY + 30 + (i-1) * 25
            local isSelected = (i == self.selectedItem)
            
            if isSelected then
                love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
                love.graphics.rectangle("fill", panelX + 15, y - 2, panelWidth - 30, 20)
            end
            
            -- Item name with rarity color
            love.graphics.setColor(item.color)
            love.graphics.print(item.name, panelX + 25, y, 0, 0.9, 0.9)
            
            -- Item stats
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(item.description, panelX + 350, y, 0, 0.8, 0.8)
            
            -- Price
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("₡" .. item.value, panelX + 600, y, 0, 0.9, 0.9)
            
            -- Affordability indicator
            if self.game.player.credits < item.value then
                love.graphics.setColor(1, 0.3, 0.3)
                love.graphics.print("INSUFFICIENT FUNDS", panelX + 700, y, 0, 0.8, 0.8)
            end
        end
        
    elseif self.selectedTab == 3 then
        -- Crew hire
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("CREW FOR HIRE:", panelX + 20, contentY, 0, 1.2, 1.2)
        
        for i, crew in ipairs(items) do
            local y = contentY + 30 + (i-1) * 25
            local isSelected = (i == self.selectedItem)
            
            if isSelected then
                love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
                love.graphics.rectangle("fill", panelX + 15, y - 2, panelWidth - 30, 20)
            end
            
            -- Crew name with rarity color
            love.graphics.setColor(crew.color)
            love.graphics.print(crew.name, panelX + 25, y, 0, 0.9, 0.9)
            
            -- Crew stats
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(crew.description, panelX + 300, y, 0, 0.8, 0.8)
            
            -- Hiring cost
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("₡" .. crew.stats.hiringCost, panelX + 500, y, 0, 0.9, 0.9)
            
            -- Affordability indicator
            if self.game.player.credits < crew.stats.hiringCost then
                love.graphics.setColor(1, 0.3, 0.3)
                love.graphics.print("INSUFFICIENT FUNDS", panelX + 600, y, 0, 0.8, 0.8)
            end
        end
    end
    
    -- Empty list message
    if #items == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Nothing available", panelX + 25, contentY + 50, 0, 1.2, 1.2)
    end
    
    -- Controls help
    love.graphics.setColor(0.6, 0.6, 0.6)
    local helpY = panelY + panelHeight - 60
    love.graphics.print("←→ Tab   ↑↓ Select   SPACE Use/Buy   F Exit", panelX + 20, helpY, 0, 1, 1)
end

return Docking
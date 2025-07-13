-- Inventory management screen

local Inventory = {}
Inventory.__index = Inventory

function Inventory:new(game)
    local inventory = setmetatable({}, Inventory)
    
    inventory.game = game
    inventory.isVisible = false
    inventory.selectedItem = 1
    inventory.selectedCategory = 1 -- 1=weapons, 2=shields, 3=engines, 4=crew
    inventory.categories = {"WEAPONS", "SHIELDS", "ENGINES", "CREW"}
    inventory.equipSlot = 1 -- For weapons and crew
    
    return inventory
end

function Inventory:toggle()
    self.isVisible = not self.isVisible
    if self.isVisible then
        self.selectedItem = 1
        self.selectedCategory = 1
    end
end

function Inventory:keypressed(key)
    if not self.isVisible then return end
    
    if key == "escape" or key == "i" then
        self:toggle()
    elseif key == "left" then
        self.selectedCategory = math.max(1, self.selectedCategory - 1)
        self.selectedItem = 1
    elseif key == "right" then
        self.selectedCategory = math.min(4, self.selectedCategory + 1)
        self.selectedItem = 1
    elseif key == "up" then
        local items = self:getCurrentCategoryItems()
        self.selectedItem = math.max(1, self.selectedItem - 1)
    elseif key == "down" then
        local items = self:getCurrentCategoryItems()
        self.selectedItem = math.min(#items, self.selectedItem + 1)
    elseif key == "return" or key == "space" then
        self:equipSelectedItem()
    elseif key == "1" then
        self.equipSlot = 1
    elseif key == "2" then
        self.equipSlot = 2
    elseif key == "3" then
        self.equipSlot = 3
    end
end

function Inventory:getCurrentCategoryItems()
    local player = self.game.player
    local items = {}
    
    for _, item in ipairs(player.inventory) do
        if self.selectedCategory == 1 and item.type == "weapon" then
            table.insert(items, item)
        elseif self.selectedCategory == 2 and item.type == "shield" then
            table.insert(items, item)
        elseif self.selectedCategory == 3 and item.type == "engine" then
            table.insert(items, item)
        elseif self.selectedCategory == 4 and item.type == "crew" then
            table.insert(items, item)
        end
    end
    
    return items
end

function Inventory:equipSelectedItem()
    local items = self:getCurrentCategoryItems()
    if self.selectedItem < 1 or self.selectedItem > #items then
        return
    end
    
    local item = items[self.selectedItem]
    local player = self.game.player
    
    if item.type == "weapon" then
        player:equipItem(item, self.equipSlot)
        print("Equipped " .. item.name .. " to slot " .. self.equipSlot)
    elseif item.type == "shield" then
        player:equipItem(item)
        print("Equipped " .. item.name)
    elseif item.type == "engine" then
        player:equipItem(item)
        print("Equipped " .. item.name)
    elseif item.type == "crew" then
        player:equipItem(item, self.equipSlot)
        print("Assigned " .. item.name .. " to crew slot " .. self.equipSlot)
    end
end

function Inventory:draw()
    if not self.isVisible then return end
    
    -- Background overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Main panel
    local panelWidth = 800
    local panelHeight = 600
    local panelX = (love.graphics.getWidth() - panelWidth) / 2
    local panelY = (love.graphics.getHeight() - panelHeight) / 2
    
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Title
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("INVENTORY", panelX + 20, panelY + 20, 0, 2.5, 2.5)
    
    -- Category tabs
    local tabWidth = 150
    local tabY = panelY + 70
    for i, category in ipairs(self.categories) do
        local tabX = panelX + 20 + (i-1) * (tabWidth + 10)
        local isSelected = (i == self.selectedCategory)
        
        if isSelected then
            love.graphics.setColor(0.2, 0.4, 0.6, 0.8)
            love.graphics.rectangle("fill", tabX, tabY, tabWidth, 30)
        end
        
        love.graphics.setColor(isSelected and {1, 1, 1} or {0.7, 0.7, 0.7})
        love.graphics.rectangle("line", tabX, tabY, tabWidth, 30)
        love.graphics.print(category, tabX + 10, tabY + 8, 0, 1, 1)
    end
    
    -- Current equipment display
    local equipX = panelX + 500
    local equipY = panelY + 120
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("EQUIPPED:", equipX, equipY, 0, 1.2, 1.2)
    
    local player = self.game.player
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("W1: " .. (player.weapon1 and player.weapon1.name or "NONE"), equipX, equipY + 25, 0, 0.8, 0.8)
    love.graphics.print("W2: " .. (player.weapon2 and player.weapon2.name or "NONE"), equipX, equipY + 40, 0, 0.8, 0.8)
    love.graphics.print("W3: " .. (player.weapon3 and player.weapon3.name or "NONE"), equipX, equipY + 55, 0, 0.8, 0.8)
    love.graphics.print("SHIELD: " .. (player.shield and player.shield.name or "NONE"), equipX, equipY + 75, 0, 0.8, 0.8)
    love.graphics.print("ENGINE: " .. (player.engine and player.engine.name or "NONE"), equipX, equipY + 90, 0, 0.8, 0.8)
    love.graphics.print("CREW 1: " .. (player.crew[1] and player.crew[1].name or "VACANT"), equipX, equipY + 110, 0, 0.8, 0.8)
    love.graphics.print("CREW 2: " .. (player.crew[2] and player.crew[2].name or "VACANT"), equipX, equipY + 125, 0, 0.8, 0.8)
    love.graphics.print("CREW 3: " .. (player.crew[3] and player.crew[3].name or "VACANT"), equipX, equipY + 140, 0, 0.8, 0.8)
    
    -- Equipment slot selector
    if self.selectedCategory == 1 or self.selectedCategory == 4 then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("SLOT: " .. self.equipSlot, equipX, equipY + 170, 0, 1, 1)
    end
    
    -- Item list
    local items = self:getCurrentCategoryItems()
    local listY = panelY + 120
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("ITEMS:", panelX + 20, listY, 0, 1.2, 1.2)
    
    for i, item in ipairs(items) do
        local y = listY + 25 + (i-1) * 25
        local isSelected = (i == self.selectedItem)
        
        if isSelected then
            love.graphics.setColor(0.2, 0.6, 0.8, 0.5)
            love.graphics.rectangle("fill", panelX + 15, y - 2, 450, 20)
        end
        
        -- Item color based on rarity
        love.graphics.setColor(item.color)
        love.graphics.print(item.name, panelX + 25, y, 0, 0.9, 0.9)
        
        -- Item stats
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(item.description, panelX + 300, y, 0, 0.8, 0.8)
        
        -- Item value
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(item.value .. " cred", panelX + 400, y, 0, 0.8, 0.8)
    end
    
    -- Controls help
    love.graphics.setColor(0.6, 0.6, 0.6)
    local helpY = panelY + panelHeight - 60
    love.graphics.print("←→ Category   ↑↓ Select   SPACE Equip   1-3 Slot   I Close", panelX + 20, helpY, 0, 1, 1)
    
    if #items == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No items in this category", panelX + 25, listY + 50, 0, 1.2, 1.2)
    end
end

return Inventory
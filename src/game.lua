-- Main game state manager

local Player = require('src.player')
local BulletManager = require('src.bullet_manager')
local BulletManagerMP = require('src.bullet_manager_mp')
local EnemyManager = require('src.enemy_manager')
local ParticleManager = require('src.particle_manager')
local AudioManager = require('src.audio_manager')
local SpaceStation = require('src.space_station')
local Settings = require('src.settings')
local ItemSystem = require('src.item')
local Item = ItemSystem.Item
local ItemGenerator = ItemSystem.ItemGenerator
local Inventory = require('src.inventory')
local Docking = require('src.docking')
local StartMenu = require('src.start_menu')
local ShipCreation = require('src.ship_creation')
-- Use mock network for testing without external dependencies
local NetworkClient = require('src.mock_network')
local PlayerManager = require('src.player_manager')
local Nexus = require('src.nexus')
local ShipClassManager = require('src.ship_class_manager')
local AbilitySystem = require('src.ability_system')
local ManaSystem = require('src.mana_system')
local DeathSystem = require('src.death_system')
local StatusEffectSystem = require('src.status_effect_system')
local WeaponPatternSystem = require('src.weapon_pattern_system')
local DefensiveSystem = require('src.defensive_system')

local Game = {}

function Game:init()
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    
    -- Game state
    self.gameState = "menu" -- "menu", "playing", "ship_creation", "multiplayer", "nexus"
    self.currentShip = nil
    self.multiplayerMode = false
    
    -- Initialize menus
    self.startMenu = StartMenu:new()
    self.shipCreation = ShipCreation:new()
    
    -- Initialize game systems (will be properly set up when starting a game)
    self.player = nil
    self.bulletManager = nil
    self.enemyManager = nil
    self.particleManager = nil
    self.audioManager = nil
    self.spaceStations = {}
    self.settings = nil
    self.inventory = nil
    self.docking = nil
    
    -- Network client for multiplayer
    self.networkClient = nil
    self.otherPlayers = {}
    
    -- Player manager for multiplayer
    self.playerManager = nil
    
    -- Nexus hub world
    self.nexus = nil
    
    -- Ship class manager
    self.shipClassManager = ShipClassManager:new()
    self.abilitySystem = AbilitySystem:new()
    self.manaSystem = ManaSystem:new()
    self.deathSystem = DeathSystem:new()
    self.statusEffectSystem = StatusEffectSystem:new()
    self.weaponPatternSystem = WeaponPatternSystem:new()
    self.defensiveSystem = DefensiveSystem:new()
    
    print("Sci-Fi Bullet Hell Game Initialized!")
end

function Game:startGame(ship)
    self.gameState = "playing"
    self.currentShip = ship
    
    -- Initialize game systems
    self.player = Player:new(self.width / 2, self.height - 100)
    self.bulletManager = BulletManager:new()
    self.enemyManager = EnemyManager:new(self.width, self.height)
    self.particleManager = ParticleManager:new()
    self.audioManager = AudioManager:new()
    
    -- Apply ship stats to player
    if ship then
        self.player.health = ship.health
        self.player.maxHealth = ship.maxHealth
        self.player.speed = ship.speed
        self.player.fireRate = ship.fireRate
        self.player.level = ship.level or 1
        self.player.credits = ship.credits or 1000
        self.player.experience = ship.experience or 0
        self.player.experienceToNext = ship.experienceToNext or 100
        
        -- Mark as local player for death system (needs to be set before ability system)
        self.player.id = "local_player"
        self.player.name = ship.name
        
        -- Initialize weapon system
        self.player.currentWeaponType = "basic"
        self.player.weaponTypes = {"basic", "spreadGun", "burstRifle", "spiralCannon", "waveBeam", "piercingRail", "explosiveCannon", "poisonDart", "slowBeam"}
        
        -- Apply ship class if available
        if ship.classType then
            self.shipClassManager:applyClassToPlayer(self.player, ship.classType)
            -- Initialize ability, mana, and defensive systems for the player
            self.abilitySystem:initializePlayer(self.player)
            self.manaSystem:initializePlayer(self.player)
            self.defensiveSystem:initializePlayer(self.player)
        end
        
        -- Apply ship appearance
        self.player.shipShape = ship.shape or "triangle"
        self.player.shipColor = ship.color or {0.2, 0.8, 1.0}
    end
    
    -- Initialize space stations
    self.spaceStations = {}
    self:generateSpaceStations()
    
    -- Initialize UI systems
    self.settings = Settings:new(self)
    self.inventory = Inventory:new(self)
    self.docking = Docking:new(self)
    
    -- Game state
    self.score = 0
    self.gameOver = false
    self.paused = false
    self.autoShoot = false
    
    -- Custom crosshair
    self.crosshair = {
        enabled = true,
        size = 20,
        thickness = 2,
        color = {0, 1, 1, 0.8}
    }
    
    -- Camera system
    self.camera = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        rotation = 0,
        targetRotation = 0,
        smoothing = 5,
        rotationSpeed = 2
    }
    
    -- Background stars
    self:generateStars()
    
    -- Start background music
    self.audioManager:startMusic()
    
    print("Game started with ship: " .. (ship.name or "Unknown"))
end

function Game:startMultiplayerGame(ship, serverIP, serverPort)
    self.gameState = "playing"
    self.currentShip = ship
    self.multiplayerMode = true
    
    -- Initialize network client
    self.networkClient = NetworkClient:new()
    local connected = self.networkClient:connect(serverIP, serverPort, ship.name)
    
    if not connected then
        print("Failed to connect to server")
        self:returnToMenu()
        return false
    end
    
    -- Initialize player manager for multiplayer
    self.playerManager = PlayerManager:new()
    
    -- Initialize game systems
    self.player = Player:new(self.width / 2, self.height - 100)
    
    -- Set local player in player manager
    self.playerManager:setLocalPlayer(self.player, self.networkClient:getClientId())
    self.bulletManager = BulletManagerMP:new()
    self.enemyManager = EnemyManager:new(self.width, self.height)
    self.particleManager = ParticleManager:new()
    self.audioManager = AudioManager:new()
    
    -- Apply ship stats to player
    if ship then
        self.player.health = ship.health
        self.player.maxHealth = ship.maxHealth
        self.player.speed = ship.speed
        self.player.fireRate = ship.fireRate
        self.player.level = ship.level or 1
        self.player.credits = ship.credits or 1000
        self.player.experience = ship.experience or 0
        self.player.experienceToNext = ship.experienceToNext or 100
        
        -- Apply ship appearance
        self.player.shipShape = ship.shape or "triangle"
        self.player.shipColor = ship.color or {0.2, 0.8, 1.0}
    end
    
    -- Initialize UI systems
    self.settings = Settings:new(self)
    self.inventory = Inventory:new(self)
    self.docking = Docking:new(self)
    
    -- Game state
    self.score = 0
    self.gameOver = false
    self.paused = false
    self.autoShoot = false
    
    -- Custom crosshair
    self.crosshair = {
        enabled = true,
        size = 20,
        thickness = 2,
        color = {0, 1, 1, 0.8}
    }
    
    -- Camera system
    self.camera = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        rotation = 0,
        targetRotation = 0,
        smoothing = 5,
        rotationSpeed = 2
    }
    
    -- Background stars
    self:generateStars()
    
    -- Start background music
    self.audioManager:startMusic()
    
    print("Multiplayer game started with ship: " .. (ship.name or "Unknown"))
    return true
end

function Game:startNexus(ship)
    self.gameState = "nexus"
    self.currentShip = ship
    self.multiplayerMode = true
    
    -- Initialize network client for nexus
    self.networkClient = NetworkClient:new()
    local connected = self.networkClient:connect("localhost", 7777, ship.name)
    
    if not connected then
        print("Failed to connect to nexus server")
        self:returnToMenu()
        return false
    end
    
    -- Initialize nexus
    self.nexus = Nexus:new(self.width, self.height)
    
    -- Initialize player manager for multiplayer
    self.playerManager = PlayerManager:new()
    
    -- Initialize minimal game systems for nexus
    self.player = Player:new(self.width / 2, self.height / 2) -- Start in center
    self.playerManager:setLocalPlayer(self.player, self.networkClient:getClientId())
    self.audioManager = AudioManager:new()
    self.particleManager = ParticleManager:new()
    
    -- Apply ship stats to player
    if ship then
        self.player.health = ship.health
        self.player.maxHealth = ship.maxHealth
        self.player.speed = ship.speed
        self.player.level = ship.level or 1
        self.player.credits = ship.credits or 1000
        
        -- Apply ship appearance
        self.player.shipShape = ship.shape or "triangle"
        self.player.shipColor = ship.color or {0.2, 0.8, 1.0}
    end
    
    -- Camera system for nexus
    self.camera = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        rotation = 0,
        targetRotation = 0,
        smoothing = 5,
        rotationSpeed = 2
    }
    
    -- Background stars
    self:generateStars()
    
    -- Start ambient music
    self.audioManager:startMusic()
    
    -- Add welcome message to nexus chat
    self.nexus:addChatMessage("Welcome to the Nexus!", "SYSTEM")
    self.nexus:addChatMessage("This is a safe zone where you can chat with other players.", "SYSTEM")
    self.nexus:addChatMessage("Use portals 1-4 to enter combat areas.", "SYSTEM")
    
    print("Entered Nexus hub with ship: " .. (ship.name or "Unknown"))
    return true
end

function Game:updateNexus(dt)
    if not self.player or not self.nexus then
        return
    end
    
    -- Update network client
    if self.networkClient then
        self.networkClient:update(dt, self.player)
        
        -- Update player manager with network data
        if self.playerManager then
            local otherPlayers = self.networkClient:getOtherPlayers()
            for _, playerData in ipairs(otherPlayers) do
                self.playerManager:updateRemotePlayer(playerData.id, playerData)
            end
            
            -- Update all players
            self.playerManager:updateAll(dt)
        end
        
        -- If not connected, return to menu
        if not self.networkClient:isConnected() then
            print("Lost connection to nexus server")
            self:returnToMenu()
            return
        end
    end
    
    -- Update camera to follow player
    self.camera.targetX = self.player.x - self.width / 2
    self.camera.targetY = self.player.y - self.height / 2
    
    -- Smooth camera movement (no rotation in nexus)
    self.camera.x = self.camera.x + (self.camera.targetX - self.camera.x) * self.camera.smoothing * dt
    self.camera.y = self.camera.y + (self.camera.targetY - self.camera.y) * self.camera.smoothing * dt
    
    -- Update stars
    for _, star in ipairs(self.stars) do
        star.y = star.y + star.speed * dt
        if star.y > self.camera.y + self.height + 100 then
            star.y = self.camera.y - 100
            star.x = self.camera.x + math.random(0, self.width)
        end
    end
    
    -- Update nexus
    self.nexus:update(dt, self.player, self.playerManager)
    
    -- Update player
    if self.playerManager then
        -- Player manager already updated players above
    else
        self.player:update(dt)
    end
    
    -- Update particle effects
    if self.particleManager then
        self.particleManager:update(dt)
    end
end

function Game:returnToMenu()
    self.gameState = "menu"
    self.startMenu:show()
    if self.audioManager then
        self.audioManager:stopMusic()
    end
    
    -- Disconnect from server if connected
    if self.networkClient then
        self.networkClient:disconnect()
        self.networkClient = nil
        self.multiplayerMode = false
        self.otherPlayers = {}
    end
    
    -- Clean up player manager
    if self.playerManager then
        self.playerManager = nil
    end
    
    -- Clean up nexus
    if self.nexus then
        self.nexus = nil
    end
end

function Game:generateStars()
    self.stars = {}
    for i = 1, 100 do
        table.insert(self.stars, {
            x = math.random(0, self.width),
            y = math.random(0, self.height),
            speed = math.random(20, 80),
            brightness = math.random() * 0.7 + 0.3
        })
    end
end

function Game:generateSpaceStations()
    local stationTypes = {"research", "military", "trading", "mining"}
    local numStations = 3
    
    for i = 1, numStations do
        local stationType = stationTypes[math.random(1, #stationTypes)]
        
        -- Position stations around the game world
        local angle = (i / numStations) * 2 * math.pi
        local distance = 800 + math.random(-200, 200)
        local x = self.width / 2 + math.cos(angle) * distance
        local y = self.height / 2 + math.sin(angle) * distance
        
        local station = SpaceStation:new(x, y, stationType)
        table.insert(self.spaceStations, station)
    end
    
    print("Generated " .. numStations .. " space stations")
end

function Game:tryDocking()
    -- Check if player is near any station
    for _, station in ipairs(self.spaceStations) do
        if station:isPlayerInDockingRange(self.player) then
            self.docking:show(station)
            print("Docked with " .. string.upper(station.type) .. " station")
            return
        end
    end
    print("No station in docking range")
end

function Game:update(dt)
    if self.gameState == "menu" or self.gameState == "ship_creation" then
        return
    end
    
    -- Handle nexus state
    if self.gameState == "nexus" then
        self:updateNexus(dt)
        return
    end
    
    if self.gameOver or self.paused or not self.player then
        return
    end
    
    -- Update network client if in multiplayer mode
    if self.multiplayerMode and self.networkClient then
        self.networkClient:update(dt, self.player)
        
        -- Update player manager with network data
        if self.playerManager then
            local otherPlayers = self.networkClient:getOtherPlayers()
            for _, playerData in ipairs(otherPlayers) do
                self.playerManager:updateRemotePlayer(playerData.id, playerData)
            end
            
            -- Update all players
            self.playerManager:updateAll(dt)
        end
        
        -- Update bullet manager with server bullets
        if self.bulletManager and self.bulletManager.updateServerBullets then
            local serverBullets = self.networkClient:getServerBullets()
            self.bulletManager:updateServerBullets(serverBullets)
        end
        
        -- Update other players from server (legacy)
        self.otherPlayers = self.networkClient:getOtherPlayers()
        
        -- If not connected, return to menu
        if not self.networkClient:isConnected() then
            print("Lost connection to server")
            self:returnToMenu()
            return
        end
    end
    
    -- Camera rotation is now handled by the player
    
    -- Update camera to follow player
    self.camera.targetX = self.player.x - self.width / 2
    self.camera.targetY = self.player.y - self.height / 2
    self.camera.targetRotation = -1 * self.player.rotation
    
    -- Smooth camera movement and rotation
    self.camera.x = self.camera.x + (self.camera.targetX - self.camera.x) * self.camera.smoothing * dt
    self.camera.y = self.camera.y + (self.camera.targetY - self.camera.y) * self.camera.smoothing * dt
    self.camera.rotation = self.camera.rotation + (self.camera.targetRotation - self.camera.rotation) * self.camera.smoothing * dt
    
    -- Update stars (scrolling background relative to camera)
    for _, star in ipairs(self.stars) do
        star.y = star.y + star.speed * dt
        -- Reset stars relative to camera position
        if star.y > self.camera.y + self.height + 100 then
            star.y = self.camera.y - 100
            star.x = self.camera.x + math.random(0, self.width)
        end
    end
    
    -- Update game systems
    if self.multiplayerMode and self.playerManager then
        -- Player manager already updated players above
    else
        -- Apply status effect modifiers before player update
        if self.statusEffectSystem then
            local speedModifier = self.statusEffectSystem:getSpeedModifier(self.player)
            self.player.statusSpeedModifier = speedModifier
            
            -- Check if player can move or shoot
            self.player.canMove = self.statusEffectSystem:canMove(self.player)
            self.player.canShoot = self.statusEffectSystem:canShoot(self.player)
            self.player.isConfused = self.statusEffectSystem:isConfused(self.player)
        end
        
        self.player:update(dt)
    end
    
    -- Update ship class effects
    if self.shipClassManager then
        self.shipClassManager:updatePlayer(self.player, dt)
    end
    
    -- Update ability and mana systems
    if self.abilitySystem then
        self.abilitySystem:update(dt)
    end
    if self.manaSystem then
        self.manaSystem:updatePlayer(self.player, dt)
    end
    
    -- Update death system
    if self.deathSystem then
        self.deathSystem:update(dt)
    end
    
    -- Update status effect system
    if self.statusEffectSystem then
        self.statusEffectSystem:update(dt)
    end
    self.bulletManager:update(dt, self.player)
    self.enemyManager:update(dt, self.player, self.bulletManager)
    self.particleManager:update(dt)
    
    -- Update space stations
    for _, station in ipairs(self.spaceStations) do
        station:update(dt, self.player)
    end
    
    -- Handle player shooting
    local shouldShoot = false
    if self.autoShoot then
        shouldShoot = true
    elseif love.mouse.isDown(1) or love.keyboard.isDown('space') then
        shouldShoot = true
    end
    
    if shouldShoot then
        local mouseX, mouseY = love.mouse.getPosition()
        
        -- Transform mouse coordinates to world space (accounting for camera rotation)
        local centerX, centerY = self.width / 2, self.height / 2
        local relativeMouseX = mouseX - centerX
        local relativeMouseY = mouseY - centerY
        
        -- Rotate mouse position by camera rotation to get world coordinates
        local worldMouseX = self.player.x + (relativeMouseX * math.cos(-self.camera.rotation) - relativeMouseY * math.sin(-self.camera.rotation))
        local worldMouseY = self.player.y + (relativeMouseX * math.sin(-self.camera.rotation) + relativeMouseY * math.cos(-self.camera.rotation))
        
        local angle = math.atan2(worldMouseY - self.player.y, worldMouseX - self.player.x)
        local didShoot = false
        
        if self.multiplayerMode and self.networkClient then
            -- In multiplayer, use predicted shooting
            if self.player.lastShot >= self.player.fireRate then
                self.player.lastShot = 0
                didShoot = true
                
                -- Add predicted bullet for immediate feedback
                if self.bulletManager and self.bulletManager.addPredictedBullet then
                    self.bulletManager:addPredictedBullet(
                        self.player.x, self.player.y, angle, 500, 25, 
                        self.networkClient:getClientId()
                    )
                end
                
                -- Notify server
                self.networkClient:sendPlayerShoot(self.player.x, self.player.y, angle)
            end
        else
            -- Single player mode
            didShoot = self.player:shoot(angle, self.bulletManager)
        end
        
        if didShoot then
            self.audioManager:playSound("shoot")
        end
    end
    
    -- Check collisions
    self:checkCollisions()
    
    -- Spawn enemies
    self.enemyManager:spawnEnemies(dt, self.player)
end

function Game:checkCollisions()
    -- Player bullets vs enemies
    for _, bullet in ipairs(self.bulletManager.playerBullets) do
        for _, enemy in ipairs(self.enemyManager.enemies) do
            if self:checkCollision(bullet, enemy) then
                enemy:takeDamage(bullet.damage)
                bullet.active = false
                self.particleManager:createExplosion(enemy.x, enemy.y, {0.9, 0.3, 0.1})
                self.audioManager:playSound("hit")
                
                if enemy.health <= 0 then
                    self.score = self.score + enemy.points
                    self.particleManager:createExplosion(enemy.x, enemy.y, {1, 0.5, 0})
                    self.audioManager:playSound("explosion")
                    
                    -- Give experience for killing enemies
                    self.player:gainExperience(enemy.points)
                    
                    -- Credit drop
                    local creditDrop = math.random(50, 200)
                    self.player.credits = self.player.credits + creditDrop
                    print("Earned " .. creditDrop .. " cred")
                    
                    -- Random item drop
                    if math.random() < 0.1 then -- 10% drop chance
                        local itemType = math.random(4)
                        local item
                        if itemType == 1 then
                            item = ItemGenerator.generateWeapon(self.player.level)
                        elseif itemType == 2 then
                            item = ItemGenerator.generateShield(self.player.level)
                        elseif itemType == 3 then
                            item = ItemGenerator.generateEngine(self.player.level)
                        else
                            item = ItemGenerator.generateCrew(self.player.level)
                        end
                        self.player:addToInventory(item)
                        print("Found: " .. item.name)
                    end
                end
            end
        end
    end
    
    -- Enemy bullets vs player (only if not docked)
    if not self.docking.isVisible then
        for _, bullet in ipairs(self.bulletManager.enemyBullets) do
            if self:checkCollision(bullet, self.player) then
                self.player:takeDamage(bullet.damage, self.deathSystem, "Enemy projectile", self.defensiveSystem)
                bullet.active = false
                self.particleManager:createExplosion(self.player.x, self.player.y, {0.1, 0.5, 0.9})
                self.audioManager:playSound("hit")
            end
        end
        
        -- Server bullets vs player (multiplayer)
        if self.multiplayerMode and self.bulletManager.checkServerBulletCollisions then
            local clientId = self.networkClient and self.networkClient:getClientId()
            local hits = self.bulletManager:checkServerBulletCollisions(self.player, clientId)
            
            for _, bullet in ipairs(hits) do
                self.player:takeDamage(bullet.damage, self.deathSystem, "Server projectile", self.defensiveSystem)
                self.particleManager:createExplosion(self.player.x, self.player.y, {0.9, 0.3, 0.1})
                self.audioManager:playSound("hit")
            end
        end
        
        -- Enemies vs player (only if not docked)
        for _, enemy in ipairs(self.enemyManager.enemies) do
            if self:checkCollision(enemy, self.player) then
                self.player:takeDamage(10, self.deathSystem, "Enemy collision", self.defensiveSystem)
                enemy.health = 0
                self.particleManager:createExplosion(self.player.x, self.player.y, {1, 0, 0})
                self.audioManager:playSound("explosion")
            end
        end
    end
    
    -- Space stations are now invulnerable - bullets pass through them
end

function Game:checkCollision(obj1, obj2)
    local dx = obj1.x - obj2.x
    local dy = obj1.y - obj2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (obj1.radius + obj2.radius)
end

function Game:draw()
    if self.gameState == "menu" then
        self.startMenu:draw()
        -- Draw settings overlay if open from menu
        if self.settings and self.settings.isVisible then
            self.settings:draw()
        end
        return
    elseif self.gameState == "ship_creation" then
        self.shipCreation:draw()
        return
    elseif self.gameState == "nexus" then
        self:drawNexus()
        return
    end
    
    if not self.player then
        return
    end
    
    -- Apply camera transform for world objects
    love.graphics.push()
    
    -- Translate to center, rotate, then translate back with camera offset
    love.graphics.translate(self.width / 2, self.height / 2)
    love.graphics.rotate(self.camera.rotation)
    love.graphics.translate(-self.width / 2 - self.camera.x, -self.height / 2 - self.camera.y)
    
    -- Draw starfield background
    love.graphics.setColor(1, 1, 1)
    for _, star in ipairs(self.stars) do
        love.graphics.setColor(star.brightness, star.brightness, star.brightness)
        love.graphics.circle('fill', star.x, star.y, 1)
    end
    
    -- Draw game objects
    if self.multiplayerMode and self.playerManager then
        -- Player manager draws all players
        self.playerManager:drawAll()
    else
        self.player:draw()
    end
    
    -- Draw ship class effects
    if self.shipClassManager then
        self.shipClassManager:drawClassEffects(self.player)
    end
    
    -- Draw defensive effects
    if self.defensiveSystem then
        self.defensiveSystem:drawDefensiveEffects(self.player)
    end
    
    self.bulletManager:draw()
    self.enemyManager:draw()
    self.particleManager:draw()
    
    -- Server bullets are now drawn by BulletManagerMP
    
    -- Draw space stations
    for _, station in ipairs(self.spaceStations) do
        station:draw()
    end
    
    love.graphics.pop()
    
    -- Draw UI (not affected by camera)
    self:drawUI()
    
    if self.gameOver then
        self:drawGameOver()
    end
    
    -- Draw UI screens on top
    self.settings:draw()
    self.inventory:draw()
    self.docking:draw()
    
    -- Draw custom crosshair
    self:drawCrosshair()
end

function Game:drawCrosshair()
    if not self.crosshair.enabled then return end
    
    local mouseX, mouseY = love.mouse.getPosition()
    love.graphics.setColor(self.crosshair.color)
    love.graphics.setLineWidth(self.crosshair.thickness)
    
    -- Draw crosshair lines
    local halfSize = self.crosshair.size / 2
    love.graphics.line(mouseX - halfSize, mouseY, mouseX + halfSize, mouseY) -- Horizontal
    love.graphics.line(mouseX, mouseY - halfSize, mouseX, mouseY + halfSize) -- Vertical
    
    -- Draw center dot
    love.graphics.circle("fill", mouseX, mouseY, 2)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function Game:drawUI()
    -- Left side HUD
    love.graphics.setColor(0, 1, 1) -- Cyan sci-fi color
    love.graphics.print("Health: " .. self.player.health, 10, 10, 0, 2, 2)
    
    -- RPG elements - right side
    local rightX = self.width - 300
    love.graphics.setColor(1, 1, 0) -- Yellow for RPG elements
    love.graphics.print("LEVEL: " .. self.player.level, rightX, 10, 0, 1.5, 1.5)
    love.graphics.print("EXP: " .. self.player.experience .. "/" .. self.player.experienceToNext, rightX, 35, 0, 1, 1)
    love.graphics.print("CREDITS: " .. self.player.credits .. " cred", rightX, 55, 0, 1, 1)
    
    -- Equipment slots
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("WEAPONS:", rightX, 85, 0, 1, 1)
    love.graphics.print("1: " .. (self.player.weapon1 and self.player.weapon1.name or "EMPTY"), rightX + 10, 105, 0, 0.8, 0.8)
    love.graphics.print("2: " .. (self.player.weapon2 and self.player.weapon2.name or "EMPTY"), rightX + 10, 120, 0, 0.8, 0.8)
    love.graphics.print("3: " .. (self.player.weapon3 and self.player.weapon3.name or "EMPTY"), rightX + 10, 135, 0, 0.8, 0.8)
    
    love.graphics.print("SHIELD: " .. (self.player.shield and self.player.shield.name or "NONE"), rightX, 155, 0, 0.9, 0.9)
    love.graphics.print("ENGINE: " .. (self.player.engine and self.player.engine.name or "BASIC"), rightX, 175, 0, 0.9, 0.9)
    
    -- Crew slots
    love.graphics.setColor(0.7, 1, 0.7)
    love.graphics.print("CREW:", rightX, 200, 0, 1, 1)
    for i = 1, 3 do
        local crew = self.player.crew[i]
        love.graphics.print(i .. ": " .. (crew and crew.name or "VACANT"), rightX + 10, 215 + (i-1)*15, 0, 0.8, 0.8)
    end
    
    -- Auto-shoot indicator
    if self.autoShoot then
        love.graphics.setColor(0, 1, 0) -- Green when active
        love.graphics.print("AUTO-SHOOT: ON", 10, 100, 0, 1.5, 1.5)
    else
        love.graphics.setColor(0.5, 0.5, 0.5) -- Gray when off
        love.graphics.print("AUTO-SHOOT: OFF", 10, 100, 0, 1.5, 1.5)
    end
    
    -- Player rotation indicator
    love.graphics.setColor(0, 1, 1) -- Cyan
    local rotationDegrees = math.floor(math.deg(self.player.rotation) % 360)
    love.graphics.print("FACING: " .. rotationDegrees .. "°", 10, 130, 0, 1.2, 1.2)
    
    -- Audio status indicators
    love.graphics.setColor(self.audioManager.musicEnabled and {0, 1, 0} or {0.5, 0.5, 0.5})
    love.graphics.print("MUSIC: " .. (self.audioManager.musicEnabled and "ON" or "OFF"), 10, 160, 0, 1, 1)
    
    love.graphics.setColor(self.audioManager.sfxEnabled and {0, 1, 0} or {0.5, 0.5, 0.5})
    love.graphics.print("SFX: " .. (self.audioManager.sfxEnabled and "ON" or "OFF"), 10, 180, 0, 1, 1)
    
    -- Ship class UI
    if self.shipClassManager then
        self.shipClassManager:drawClassUI(self.player, self.width - 300, 280)
    end
    
    -- Mana bar
    if self.manaSystem and self.player.mana then
        self.manaSystem:drawManaBar(self.player, 10, 50, 200, 12)
        self.manaSystem:drawManaEffects(self.player)
    end
    
    -- Ability UI
    if self.abilitySystem then
        self.abilitySystem:drawAbilityUI(self.player, 10, self.height - 60)
    end
    
    -- Death system UI
    if self.deathSystem then
        self.deathSystem:drawDeathUI(self.player, self.width/2 - 100, self.height/2 - 50)
    end
    
    -- Status effects UI
    if self.statusEffectSystem then
        self.statusEffectSystem:drawEffects(self.player, 10, 70)
        
        -- Status effect summary
        local effectSummary = self.statusEffectSystem:getEffectSummary(self.player)
        if effectSummary ~= "No effects" then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("Effects: " .. effectSummary, 220, 50, 0, 0.8, 0.8)
        end
    end
    
    -- Defensive system UI
    if self.defensiveSystem then
        self.defensiveSystem:drawDefensiveUI(self.player, self.width - 300, 380)
    end
    
    -- Current weapon info
    if self.weaponPatternSystem and self.player.currentWeaponType then
        local weaponInfo = self.weaponPatternSystem.weaponTypes[self.player.currentWeaponType]
        if weaponInfo then
            love.graphics.setColor(0, 1, 0.5)
            love.graphics.print("WEAPON: " .. weaponInfo.name, 10, 100, 0, 1.2, 1.2)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print("DMG: " .. weaponInfo.damage .. " | Rate: " .. string.format("%.1f", weaponInfo.fireRate) .. "s", 10, 120, 0, 0.9, 0.9)
            love.graphics.print("Special: " .. self.weaponPatternSystem:getWeaponSpecialText(weaponInfo), 10, 135, 0, 0.8, 0.8)
            love.graphics.print("[J/K] Switch Weapons", 10, 150, 0, 0.7, 0.7)
        end
    end
    
    -- Controls help
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("CONTROLS: [I] Inventory  [TAB] Settings  [F] Dock  [1-4] Class Abilities", 10, self.height - 40, 0, 0.9, 0.9)
    love.graphics.print("WASD Move  QE Rotate  [G] Auto-shoot  [P] Pause", 10, self.height - 25, 0, 0.9, 0.9)
    
    -- Health bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', 10, 40, 200, 20)
    love.graphics.setColor(0, 1, 0)
    local healthPercent = self.player.health / self.player.maxHealth
    love.graphics.rectangle('fill', 10, 40, 200 * healthPercent, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 10, 40, 200, 20)
    
    -- Space station proximity indicators
    local yOffset = 210
    for _, station in ipairs(self.spaceStations) do
        local distance = math.sqrt((self.player.x - station.x)^2 + (self.player.y - station.y)^2)
        
        if distance <= station.commRange then
            love.graphics.setColor(station.color[1], station.color[2], station.color[3], 1.0)
            if distance <= station.dockingRange then
                love.graphics.print("[F] DOCK: " .. string.upper(station.type) .. " STATION", 10, yOffset, 0, 1.2, 1.2)
            else
                love.graphics.print("[COMM] " .. string.upper(station.type) .. " STATION", 10, yOffset, 0, 1, 1)
            end
            yOffset = yOffset + 25
        end
    end
end

function Game:drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, self.width, self.height)
    
    love.graphics.setColor(1, 0, 0)
    local text = "GAME OVER"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text) * 4
    love.graphics.print(text, self.width/2 - textWidth/2, self.height/2 - 50, 0, 4, 4)
    
    love.graphics.setColor(1, 1, 1)
    local scoreText = "Final Score: " .. self.score
    local scoreWidth = font:getWidth(scoreText) * 2
    love.graphics.print(scoreText, self.width/2 - scoreWidth/2, self.height/2 + 20, 0, 2, 2)
    
    local restartText = "Press R to restart"
    local restartWidth = font:getWidth(restartText) * 1.5
    love.graphics.print(restartText, self.width/2 - restartWidth/2, self.height/2 + 60, 0, 1.5, 1.5)
end

function Game:keypressed(key)
    -- Handle menu states
    if self.gameState == "menu" then
        -- Settings screen has priority when open
        if self.settings and self.settings.isVisible then
            self.settings:keypressed(key)
            return
        end
        
        local result, data = self.startMenu:keypressed(key)
        if result == "create_ship" then
            self.gameState = "ship_creation"
            self.shipCreation:show(data)
        elseif result == "load_ship" then
            self:startGame(data)
        elseif result == "test_multiplayer" then
            self:startMultiplayerGame(data, "localhost", 7777)
        elseif result == "enter_nexus" then
            self:startNexus(data)
        elseif result == "settings" then
            -- Initialize temporary settings if needed
            if not self.settings then
                self.settings = Settings:new(self)
            end
            self.settings:toggle()
        elseif result == "exit" then
            love.event.quit()
        end
        return
    elseif self.gameState == "ship_creation" then
        local result, data = self.shipCreation:keypressed(key)
        if result == "create" then
            self:startGame(data)
        elseif result == "cancel" then
            self.gameState = "menu"
            self.shipCreation:hide()
        end
        return
    elseif self.gameState == "nexus" then
        self:handleNexusInput(key)
        return
    end
    
    -- Game UI screens handle their own input
    if self.settings and self.settings.isVisible then
        self.settings:keypressed(key)
        return
    elseif self.inventory and self.inventory.isVisible then
        self.inventory:keypressed(key)
        return
    elseif self.docking and self.docking.isVisible then
        self.docking:keypressed(key)
        return
    end
    
    if key == 'escape' then
        love.event.quit()
    elseif key == 'tab' then
        self.settings:toggle()
    elseif key == 'i' then
        self.inventory:toggle()
    elseif key == 'f' then
        self:tryDocking()
    elseif key == 'p' then
        self.paused = not self.paused
        if self.paused then
            self.audioManager:pauseMusic()
        else
            self.audioManager:resumeMusic()
        end
    elseif key == 'g' then
        self.autoShoot = not self.autoShoot
        print("Auto-shoot " .. (self.autoShoot and "ENABLED" or "DISABLED"))
    elseif key == 'm' then
        local musicEnabled = self.audioManager:toggleMusic()
        print("Music " .. (musicEnabled and "ENABLED" or "DISABLED"))
    elseif key == 'n' then
        local sfxEnabled = self.audioManager:toggleSfx()
        print("Sound effects " .. (sfxEnabled and "ENABLED" or "DISABLED"))
    elseif key == 'r' then
        if self.gameOver then
            self:init() -- Restart game
        else
            -- Reset player rotation when not in game over
            self.player.rotation = 0
            print("Player rotation reset")
        end
    elseif key == '1' or key == '2' or key == '3' or key == '4' then
        -- Use class abilities (only during gameplay)
        if self.gameState ~= "playing" then return end
        
        local abilityIndex = tonumber(key)
        if self.abilitySystem and self.player then
            local success = self.abilitySystem:useAbility(self.player, abilityIndex)
            if not success then
                local abilityInfo = self.abilitySystem:getAbilityInfo(self.player, abilityIndex)
                if abilityInfo then
                    if not abilityInfo.canUse then
                        if abilityInfo.cooldownRemaining > 0 then
                            print("Ability on cooldown: " .. string.format("%.1f", abilityInfo.cooldownRemaining) .. "s")
                        elseif self.player.mana < abilityInfo.manaCost then
                            print("Not enough mana: " .. abilityInfo.manaCost .. " required")
                        end
                    end
                else
                    print("No ability in slot " .. abilityIndex)
                end
            end
        end
    elseif key == 'z' then
        -- Test status effects (for development)
        if self.statusEffectSystem and self.player then
            self.statusEffectSystem:applyEffect(self.player, "paralyzed", 3.0, 1.0, self.defensiveSystem)
        end
    elseif key == 'x' then
        -- Test status effects (for development)
        if self.statusEffectSystem and self.player then
            self.statusEffectSystem:applyEffect(self.player, "slowed", 5.0, 1.0, self.defensiveSystem)
        end
    elseif key == 'c' then
        -- Test status effects (for development)
        if self.statusEffectSystem and self.player then
            self.statusEffectSystem:applyEffect(self.player, "weakness", 4.0, 1.0, self.defensiveSystem)
        end
    elseif key == 'v' then
        -- Test armor break (for development)
        if self.statusEffectSystem and self.player then
            self.statusEffectSystem:applyEffect(self.player, "armorBreak", 5.0, 1.0, self.defensiveSystem)
        end
    elseif key == 'b' then
        -- Test bleeding (for development)
        if self.statusEffectSystem and self.player then
            self.statusEffectSystem:applyEffect(self.player, "bleeding", 6.0, 1.0, self.defensiveSystem)
        end
    elseif key == 'u' then
        -- Test confused (for development)
        if self.statusEffectSystem and self.player then
            self.statusEffectSystem:applyEffect(self.player, "confused", 8.0, 1.0, self.defensiveSystem)
        end
    elseif key == 'k' then
        -- Cycle weapons forward
        if self.player and self.player.weaponTypes then
            local currentIndex = 1
            for i, weaponType in ipairs(self.player.weaponTypes) do
                if weaponType == self.player.currentWeaponType then
                    currentIndex = i
                    break
                end
            end
            
            local nextIndex = (currentIndex % #self.player.weaponTypes) + 1
            self.player.currentWeaponType = self.player.weaponTypes[nextIndex]
            
            local weaponInfo = self.weaponPatternSystem.weaponTypes[self.player.currentWeaponType]
            print("Switched to: " .. weaponInfo.name)
        end
    elseif key == 'j' then
        -- Cycle weapons backward
        if self.player and self.player.weaponTypes then
            local currentIndex = 1
            for i, weaponType in ipairs(self.player.weaponTypes) do
                if weaponType == self.player.currentWeaponType then
                    currentIndex = i
                    break
                end
            end
            
            local prevIndex = currentIndex - 1
            if prevIndex < 1 then prevIndex = #self.player.weaponTypes end
            self.player.currentWeaponType = self.player.weaponTypes[prevIndex]
            
            local weaponInfo = self.weaponPatternSystem.weaponTypes[self.player.currentWeaponType]
            print("Switched to: " .. weaponInfo.name)
        end
    end
end

function Game:keyreleased(key)
    -- Handle key releases if needed
end

function Game:mousepressed(x, y, button)
    -- Handle mouse press if needed
end

function Game:mousereleased(x, y, button)
    -- Handle mouse release if needed
end

function Game:drawOtherPlayers()
    for _, otherPlayer in ipairs(self.otherPlayers) do
        love.graphics.push()
        love.graphics.translate(otherPlayer.x, otherPlayer.y)
        love.graphics.rotate(otherPlayer.rotation or 0)
        
        -- Draw other player's ship (simplified version)
        love.graphics.setColor(0.8, 0.8, 0.8) -- Gray color for other players
        love.graphics.polygon('fill', 
            0, -15,        -- Top point (forward)
            -9, 12,        -- Bottom left
            9, 12          -- Bottom right
        )
        
        -- Draw outline
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(1)
        love.graphics.polygon('line', 
            0, -15,
            -9, 12,
            9, 12
        )
        
        love.graphics.pop()
        
        -- Draw player name above ship
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.print("Player " .. otherPlayer.id, otherPlayer.x - 30, otherPlayer.y - 35)
        
        -- Draw health bar
        local healthPercent = otherPlayer.health / 100 -- Assuming max health 100
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle('fill', otherPlayer.x - 20, otherPlayer.y - 25, 40, 4)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle('fill', otherPlayer.x - 20, otherPlayer.y - 25, 40 * healthPercent, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle('line', otherPlayer.x - 20, otherPlayer.y - 25, 40, 4)
    end
end

function Game:drawServerBullets()
    if not self.networkClient then
        return
    end
    
    local serverBullets = self.networkClient:getServerBullets()
    
    for _, bullet in ipairs(serverBullets) do
        -- Only draw bullets from other players
        if bullet.playerId ~= self.networkClient:getClientId() then
            love.graphics.setColor(1, 0.3, 0.3) -- Red bullets for other players
            love.graphics.circle('fill', bullet.x, bullet.y, 3)
        end
    end
end

function Game:drawNexus()
    if not self.nexus or not self.player then
        return
    end
    
    -- Apply camera transform for world objects
    love.graphics.push()
    love.graphics.translate(-self.camera.x, -self.camera.y)
    
    -- Draw starfield background
    love.graphics.setColor(1, 1, 1)
    for _, star in ipairs(self.stars) do
        love.graphics.setColor(star.brightness, star.brightness, star.brightness)
        love.graphics.circle('fill', star.x, star.y, 1)
    end
    
    -- Draw nexus world
    self.nexus:draw(self.camera, self.playerManager)
    
    -- Draw players
    if self.playerManager then
        self.playerManager:drawAll()
    else
        self.player:draw()
    end
    
    -- Draw ship class effects
    if self.shipClassManager then
        self.shipClassManager:drawClassEffects(self.player)
    end
    
    -- Draw particles
    if self.particleManager then
        self.particleManager:draw()
    end
    
    love.graphics.pop()
    
    -- Draw nexus UI (not affected by camera)
    self.nexus:drawUI()
    
    -- Draw player info
    self:drawNexusPlayerInfo()
end

function Game:drawNexusPlayerInfo()
    -- Simple player info for nexus
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("Health: " .. self.player.health, 10, 10, 0, 1.5, 1.5)
    love.graphics.print("Level: " .. self.player.level, 10, 35, 0, 1.5, 1.5)
    
    -- Connection status
    if self.networkClient and self.networkClient:isConnected() then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("CONNECTED TO NEXUS", 10, 60)
        
        -- Player count
        local playerCount = self.playerManager and self.playerManager:getPlayerCount() or 1
        love.graphics.print("Players Online: " .. playerCount, 10, 80)
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("DISCONNECTED", 10, 60)
    end
    
    love.graphics.setColor(1, 1, 1)
end

function Game:handleNexusInput(key)
    if not self.nexus then
        return
    end
    
    local result, data = self.nexus:keypressed(key)
    
    if result == "chat" then
        -- Send chat message to server/other players
        if self.networkClient then
            print("Chat: " .. data) -- For now, just print locally
            self.nexus:addChatMessage(data, self.currentShip.name or "Player")
        end
    elseif result == "portal" then
        -- Enter combat area via portal
        print("Entering portal: " .. data.name)
        self:startMultiplayerGame(self.currentShip, "localhost", 7777)
    elseif result == "leave_nexus" then
        self:returnToMenu()
    end
end

function Game:textinput(text)
    if self.gameState == "nexus" and self.nexus then
        self.nexus:textinput(text)
    end
end

return Game
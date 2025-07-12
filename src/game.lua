-- Main game state manager

local Player = require('src.player')
local BulletManager = require('src.bullet_manager')
local EnemyManager = require('src.enemy_manager')
local ParticleManager = require('src.particle_manager')
local AudioManager = require('src.audio_manager')
local SpaceStation = require('src.space_station')

local Game = {}

function Game:init()
    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()
    
    -- Initialize game systems
    self.player = Player:new(self.width / 2, self.height - 100)
    self.bulletManager = BulletManager:new()
    self.enemyManager = EnemyManager:new(self.width, self.height)
    self.particleManager = ParticleManager:new()
    self.audioManager = AudioManager:new()
    
    -- Initialize space stations
    self.spaceStations = {}
    self:generateSpaceStations()
    
    -- Game state
    self.score = 0
    self.gameOver = false
    self.paused = false
    self.autoShoot = false
    
    -- Camera system
    self.camera = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        rotation = 0,
        targetRotation = 0,
        smoothing = 5, -- Camera smoothing factor
        rotationSpeed = 2 -- Rotation speed (radians per second)
    }
    
    -- Background stars
    self:generateStars()
    
    -- Start background music
    self.audioManager:startMusic()
    
    print("Sci-Fi Bullet Hell Game Initialized!")
end

function Game:generateStars()
    self.stars = {}
    for i = 1, 100 do
        table.insert(self.stars, {
            x = math.random(0, self.width),
            y = math.random(0, self.height),
            speed = math.random(20, 80),
            brightness = math.random(0.3, 1.0)
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

function Game:update(dt)
    if self.gameOver or self.paused then
        return
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
    self.player:update(dt)
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
        local didShoot = self.player:shoot(angle, self.bulletManager)
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
                end
            end
        end
    end
    
    -- Enemy bullets vs player
    for _, bullet in ipairs(self.bulletManager.enemyBullets) do
        if self:checkCollision(bullet, self.player) then
            self.player:takeDamage(bullet.damage)
            bullet.active = false
            self.particleManager:createExplosion(self.player.x, self.player.y, {0.1, 0.5, 0.9})
            self.audioManager:playSound("hit")
            
            if self.player.health <= 0 then
                self.gameOver = true
                self.audioManager:stopMusic()
            end
        end
    end
    
    -- Enemies vs player
    for _, enemy in ipairs(self.enemyManager.enemies) do
        if self:checkCollision(enemy, self.player) then
            self.player:takeDamage(10)
            enemy.health = 0
            self.particleManager:createExplosion(self.player.x, self.player.y, {1, 0, 0})
            self.audioManager:playSound("explosion")
            
            if self.player.health <= 0 then
                self.gameOver = true
                self.audioManager:stopMusic()
            end
        end
    end
    
    -- Bullets vs space stations (they can be damaged)
    for _, bullet in ipairs(self.bulletManager.enemyBullets) do
        for _, station in ipairs(self.spaceStations) do
            if self:checkCollision(bullet, station) then
                station:takeDamage(bullet.damage)
                bullet.active = false
                self.particleManager:createExplosion(station.x, station.y, {0.2, 0.8, 1.0})
                self.audioManager:playSound("hit")
            end
        end
    end
end

function Game:checkCollision(obj1, obj2)
    local dx = obj1.x - obj2.x
    local dy = obj1.y - obj2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (obj1.radius + obj2.radius)
end

function Game:draw()
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
    self.player:draw()
    self.bulletManager:draw()
    self.enemyManager:draw()
    self.particleManager:draw()
    
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
end

function Game:drawUI()
    love.graphics.setColor(0, 1, 1) -- Cyan sci-fi color
    love.graphics.print("Score: " .. self.score, 10, 10, 0, 2, 2)
    love.graphics.print("Health: " .. self.player.health, 10, 40, 0, 2, 2)
    
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
    
    -- Health bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', 10, 70, 200, 20)
    love.graphics.setColor(0, 1, 0)
    local healthPercent = self.player.health / self.player.maxHealth
    love.graphics.rectangle('fill', 10, 70, 200 * healthPercent, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 10, 70, 200, 20)
    
    -- Space station proximity indicators
    local yOffset = 210
    for _, station in ipairs(self.spaceStations) do
        local distance = math.sqrt((self.player.x - station.x)^2 + (self.player.y - station.y)^2)
        
        if distance <= station.commRange then
            love.graphics.setColor(station.color[1], station.color[2], station.color[3], 1.0)
            if distance <= station.dockingRange then
                love.graphics.print("[DOCK] " .. string.upper(station.type) .. " STATION", 10, yOffset, 0, 1.2, 1.2)
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
    if key == 'escape' then
        love.event.quit()
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

return Game
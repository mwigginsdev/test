-- Enemy spawning and management system

local Enemy = require('src.enemy')

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager:new(screenWidth, screenHeight)
    local manager = setmetatable({}, EnemyManager)
    
    manager.enemies = {}
    manager.spawnTimer = 0
    manager.spawnRate = 2.0 -- Start spawning every 2 seconds
    manager.minSpawnRate = 0.5
    manager.screenWidth = screenWidth
    manager.screenHeight = screenHeight
    manager.waveNumber = 1
    manager.enemiesSpawned = 0
    
    return manager
end

function EnemyManager:spawnEnemies(dt, player)
    self.spawnTimer = self.spawnTimer + dt
    
    if self.spawnTimer >= self.spawnRate then
        self.spawnTimer = 0
        self:spawnEnemy(player)
        
        -- Gradually increase difficulty
        self.enemiesSpawned = self.enemiesSpawned + 1
        if self.enemiesSpawned % 10 == 0 then
            self.spawnRate = math.max(self.minSpawnRate, self.spawnRate - 0.1)
            self.waveNumber = self.waveNumber + 1
        end
    end
end

function EnemyManager:spawnEnemy(player)
    local enemyTypes = {'scout', 'fighter', 'bomber'}
    local type = enemyTypes[math.random(1, #enemyTypes)]
    
    if not player then return end
    
    -- Spawn around the player's current position
    local spawnDistance = 400
    local angle = math.random() * math.pi * 2
    local x = player.x + math.cos(angle) * spawnDistance
    local y = player.y + math.sin(angle) * spawnDistance
    
    -- Bias spawning towards the top and sides (more natural for bullet hell)
    if math.random() < 0.6 then
        y = player.y - spawnDistance + math.random(-100, 100)
        x = player.x + math.random(-spawnDistance, spawnDistance)
    end
    
    table.insert(self.enemies, Enemy:new(x, y, type, self.waveNumber))
end

function EnemyManager:update(dt, player, bulletManager)
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        enemy:update(dt, player, bulletManager)
        
        -- Remove dead enemies or enemies too far from player
        local dx = enemy.x - player.x
        local dy = enemy.y - player.y
        local distanceFromPlayer = math.sqrt(dx * dx + dy * dy)
        
        if enemy.health <= 0 or distanceFromPlayer > 800 then
            table.remove(self.enemies, i)
        end
    end
end

function EnemyManager:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

return EnemyManager
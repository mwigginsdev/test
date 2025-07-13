-- Unit tests for the game

local luaunit = require('luaunit')

-- Initialize random seed for consistent testing
math.randomseed(12345)

-- Mock love2d functions for testing
local love = {
    graphics = {
        getWidth = function() return 1024 end,
        getHeight = function() return 768 end,
        getFont = function() return {getWidth = function() return 10 end} end,
        setColor = function() end,
        print = function() end,
        rectangle = function() end,
        circle = function() end,
        line = function() end,
        polygon = function() end,
        push = function() end,
        pop = function() end,
        translate = function() end,
        rotate = function() end,
        setLineWidth = function() end
    },
    sound = {
        newSoundData = function(samples, rate, bits, channels) 
            return {setSample = function() end}
        end
    },
    audio = {
        newSource = function(data, type)
            return {
                setLooping = function() end,
                setVolume = function() end,
                clone = function() return {} end,
                isPlaying = function() return false end,
                stop = function() end,
                pause = function() end,
                resume = function() end
            }
        end,
        play = function() end
    },
    mouse = {
        getPosition = function() return 100, 100 end,
        isDown = function() return false end
    },
    keyboard = {
        isDown = function() return false end
    }
}
_G.love = love

-- Add parent directory to package path
package.path = package.path .. ";../?.lua;../src/?.lua"

-- Load modules
local Game = require('game')
local Player = require('player')
local Item = require('item').Item
local ItemGenerator = require('item').ItemGenerator
local SpaceStation = require('space_station')

TestGame = {}

function TestGame:setUp()
    self.game = Game
    self.game:init()
end

function TestGame:testGameInitialization()
    luaunit.assertNotNil(self.game)
    luaunit.assertEquals(self.game.gameState, "menu")
    luaunit.assertNotNil(self.game.startMenu)
    luaunit.assertNotNil(self.game.shipCreation)
end

function TestGame:testStartGame()
    local testShip = {
        name = "TEST SHIP",
        style = 1,
        level = 1,
        credits = 1000,
        health = 100,
        maxHealth = 100,
        speed = 300,
        fireRate = 0.15
    }
    
    self.game:startGame(testShip)
    luaunit.assertEquals(self.game.gameState, "playing")
    luaunit.assertNotNil(self.game.player)
    luaunit.assertEquals(self.game.player.credits, 1000)
    luaunit.assertEquals(self.game.player.health, 100)
end

TestPlayer = {}

function TestPlayer:setUp()
    self.player = Player:new(100, 100)
end

function TestPlayer:testPlayerCreation()
    luaunit.assertNotNil(self.player)
    luaunit.assertEquals(self.player.x, 100)
    luaunit.assertEquals(self.player.y, 100)
    luaunit.assertEquals(self.player.level, 1)
    luaunit.assertEquals(self.player.credits, 1000)
    luaunit.assertEquals(self.player.health, 100)
end

function TestPlayer:testExperienceGain()
    local initialLevel = self.player.level
    local initialExp = self.player.experience
    
    self.player:gainExperience(50)
    luaunit.assertEquals(self.player.experience, initialExp + 50)
    
    -- Test level up
    self.player:gainExperience(100)  -- Should level up
    luaunit.assertEquals(self.player.level, initialLevel + 1)
end

function TestPlayer:testItemEquipping()
    local weapon = ItemGenerator.generateWeapon(1)
    self.player:equipItem(weapon, 1)
    luaunit.assertEquals(self.player.weapon1, weapon)
    
    local shield = ItemGenerator.generateShield(1)
    self.player:equipItem(shield)
    luaunit.assertEquals(self.player.shield, shield)
end

function TestPlayer:testInventoryManagement()
    local initialCount = #self.player.inventory
    local item = ItemGenerator.generateWeapon(1)
    
    self.player:addToInventory(item)
    luaunit.assertEquals(#self.player.inventory, initialCount + 1)
    luaunit.assertEquals(self.player.inventory[#self.player.inventory], item)
end

TestItemSystem = {}

function TestItemSystem:testItemCreation()
    local item = Item:new("weapon", "Test Weapon", "common", {damage = 25}, "Test item")
    
    luaunit.assertNotNil(item)
    luaunit.assertEquals(item.type, "weapon")
    luaunit.assertEquals(item.name, "Test Weapon")
    luaunit.assertEquals(item.rarity, "common")
    luaunit.assertEquals(item.stats.damage, 25)
end

function TestItemSystem:testWeaponGeneration()
    local weapon = ItemGenerator.generateWeapon(1)
    
    luaunit.assertNotNil(weapon)
    luaunit.assertEquals(weapon.type, "weapon")
    luaunit.assertNotNil(weapon.stats.damage)
    luaunit.assertNotNil(weapon.stats.fireRate)
    luaunit.assertTrue(weapon.stats.damage > 0)
end

function TestItemSystem:testShieldGeneration()
    local shield = ItemGenerator.generateShield(1)
    
    luaunit.assertNotNil(shield)
    luaunit.assertEquals(shield.type, "shield")
    luaunit.assertNotNil(shield.stats.capacity)
    luaunit.assertNotNil(shield.stats.regenRate)
    luaunit.assertTrue(shield.stats.capacity > 0)
end

function TestItemSystem:testEngineGeneration()
    local engine = ItemGenerator.generateEngine(1)
    
    luaunit.assertNotNil(engine)
    luaunit.assertEquals(engine.type, "engine")
    luaunit.assertNotNil(engine.stats.speedBonus)
    luaunit.assertTrue(engine.stats.speedBonus > 0)
end

function TestItemSystem:testCrewGeneration()
    local crew = ItemGenerator.generateCrew(1)
    
    luaunit.assertNotNil(crew)
    luaunit.assertEquals(crew.type, "crew")
    luaunit.assertNotNil(crew.stats.skill)
    luaunit.assertNotNil(crew.stats.bonus)
    luaunit.assertTrue(crew.stats.bonus > 0)
end

function TestItemSystem:testRarityScaling()
    -- Generate many items and check that rare items have better stats
    local commonDamage = 0
    local rareDamage = 0
    
    for i = 1, 100 do
        local weapon = ItemGenerator.generateWeapon(5)  -- Higher level for more rare items
        if weapon.rarity == "common" then
            commonDamage = math.max(commonDamage, weapon.stats.damage)
        elseif weapon.rarity == "rare" or weapon.rarity == "epic" or weapon.rarity == "legendary" then
            rareDamage = math.max(rareDamage, weapon.stats.damage)
        end
    end
    
    -- Rare items should generally have higher damage
    luaunit.assertTrue(rareDamage >= commonDamage)
end

TestSpaceStation = {}

function TestSpaceStation:testStationCreation()
    local station = SpaceStation:new(100, 100, "trading")
    
    luaunit.assertNotNil(station)
    luaunit.assertEquals(station.x, 100)
    luaunit.assertEquals(station.y, 100)
    luaunit.assertEquals(station.type, "trading")
    luaunit.assertTrue(#station.services > 0)
end

function TestSpaceStation:testStationInventory()
    local station = SpaceStation:new(100, 100, "trading")
    
    luaunit.assertTrue(#station.inventory > 0)
    luaunit.assertTrue(#station.availableCrew > 0)
end

function TestSpaceStation:testStationServices()
    local station = SpaceStation:new(100, 100, "trading")
    
    luaunit.assertTrue(station:canProvideService("trade"))
    luaunit.assertFalse(station:canProvideService("nonexistent"))
end

function TestSpaceStation:testHiring()
    local station = SpaceStation:new(100, 100, "trading")
    local player = Player:new(100, 100)
    player.credits = 10000  -- Ensure sufficient funds
    
    local initialCrewCount = 0
    for i = 1, 3 do
        if player.crew[i] then
            initialCrewCount = initialCrewCount + 1
        end
    end
    
    local success, message = station:hireCrew(1, player)
    
    if success then
        local newCrewCount = 0
        for i = 1, 3 do
            if player.crew[i] then
                newCrewCount = newCrewCount + 1
            end
        end
        luaunit.assertEquals(newCrewCount, initialCrewCount + 1)
    end
end

TestSettings = {}

function TestSettings:setUp()
    self.game = Game
    self.game:init()
    self.game.settings = require('settings'):new(self.game)
end

function TestSettings:testSettingsFromMenu()
    -- Test that settings can be accessed from menu
    luaunit.assertEquals(self.game.gameState, "menu")
    luaunit.assertNotNil(self.game.settings)
    
    -- Initialize minimal audio manager for settings
    self.game.audioManager = {
        musicVolume = 0.6,
        sfxVolume = 0.8,
        musicEnabled = true,
        sfxEnabled = true,
        setMusicVolume = function() end,
        setSfxVolume = function() end,
        startMusic = function() end,
        stopMusic = function() end
    }
    
    -- Test toggle functionality
    local initialVisible = self.game.settings.isVisible
    self.game.settings:toggle()
    luaunit.assertNotEquals(self.game.settings.isVisible, initialVisible)
end

function TestSettings:testSettingsValues()
    local settings = self.game.settings
    
    -- Test default values exist
    luaunit.assertNotNil(settings.values.musicVolume)
    luaunit.assertNotNil(settings.values.sfxVolume)
    luaunit.assertNotNil(settings.values.autoShoot)
    luaunit.assertTrue(settings.values.musicVolume >= 0 and settings.values.musicVolume <= 1)
    luaunit.assertTrue(settings.values.sfxVolume >= 0 and settings.values.sfxVolume <= 1)
end

TestShipAppearance = {}

function TestShipAppearance:setUp()
    self.game = Game
    self.game:init()
end

function TestShipAppearance:testShipCreationProperties()
    local testShip = {
        name = "TEST SHIP",
        style = 2, -- Interceptor
        shape = "arrow",
        color = {1.0, 0.3, 0.3},
        level = 1,
        credits = 1000,
        health = 80,
        maxHealth = 80,
        speed = 400,
        fireRate = 0.12
    }
    
    self.game:startGame(testShip)
    
    -- Test that ship appearance is applied
    luaunit.assertEquals(self.game.player.shipShape, "arrow")
    luaunit.assertEquals(self.game.player.shipColor[1], 1.0)
    luaunit.assertEquals(self.game.player.shipColor[2], 0.3)
    luaunit.assertEquals(self.game.player.shipColor[3], 0.3)
end

function TestShipAppearance:testAllShipShapes()
    local shapes = {"triangle", "arrow", "pentagon", "diamond"}
    
    for _, shape in ipairs(shapes) do
        local testShip = {
            name = "TEST " .. shape:upper(),
            shape = shape,
            color = {0.5, 0.5, 0.5},
            health = 100,
            maxHealth = 100,
            speed = 300,
            fireRate = 0.15
        }
        
        self.game:startGame(testShip)
        luaunit.assertEquals(self.game.player.shipShape, shape)
        
        -- Test that player has drawing functions for all shapes
        luaunit.assertNotNil(self.game.player.drawShipShape)
        luaunit.assertNotNil(self.game.player.drawShipShapeOutline)
    end
end

TestMenuIntegration = {}

function TestMenuIntegration:setUp()
    self.game = Game
    self.game:init()
end

function TestMenuIntegration:testGameStateTransitions()
    -- Test initial state
    luaunit.assertEquals(self.game.gameState, "menu")
    
    -- Test ship creation transition
    self.game.gameState = "ship_creation"
    luaunit.assertEquals(self.game.gameState, "ship_creation")
    
    -- Test playing transition
    local testShip = {name = "TEST", shape = "triangle", color = {1,1,1}, health = 100, maxHealth = 100, speed = 300, fireRate = 0.15}
    self.game:startGame(testShip)
    luaunit.assertEquals(self.game.gameState, "playing")
end

function TestMenuIntegration:testReturnToMenu()
    -- Start a game first
    local testShip = {name = "TEST", shape = "triangle", color = {1,1,1}, health = 100, maxHealth = 100, speed = 300, fireRate = 0.15}
    self.game:startGame(testShip)
    luaunit.assertEquals(self.game.gameState, "playing")
    
    -- Return to menu
    self.game:returnToMenu()
    luaunit.assertEquals(self.game.gameState, "menu")
end

-- Test runner
if arg and arg[0]:match("test_game.lua$") then
    -- Run specific test sets
    
    -- Add test methods manually since we can't auto-discover
    local testCount = 0
    local passCount = 0
    local failCount = 0
    
    local function runTest(testClass, testMethod)
        testCount = testCount + 1
        local success, error = pcall(function()
            if testClass.setUp then testClass:setUp() end
            testClass[testMethod](testClass)
        end)
        
        if success then
            passCount = passCount + 1
            print("PASS: " .. testMethod)
        else
            failCount = failCount + 1
            print("FAIL: " .. testMethod .. " - " .. tostring(error))
        end
    end
    
    print("Running comprehensive test suite...")
    
    -- Run all tests
    runTest(TestGame, "testGameInitialization")
    runTest(TestGame, "testStartGame")
    runTest(TestPlayer, "testPlayerCreation")
    runTest(TestPlayer, "testExperienceGain")
    runTest(TestPlayer, "testItemEquipping")
    runTest(TestPlayer, "testInventoryManagement")
    runTest(TestItemSystem, "testItemCreation")
    runTest(TestItemSystem, "testWeaponGeneration")
    runTest(TestItemSystem, "testShieldGeneration")
    runTest(TestItemSystem, "testEngineGeneration")
    runTest(TestItemSystem, "testCrewGeneration")
    runTest(TestItemSystem, "testRarityScaling")
    runTest(TestSpaceStation, "testStationCreation")
    runTest(TestSpaceStation, "testStationInventory")
    runTest(TestSpaceStation, "testStationServices")
    runTest(TestSettings, "testSettingsFromMenu")
    runTest(TestSettings, "testSettingsValues")
    runTest(TestShipAppearance, "testShipCreationProperties")
    runTest(TestShipAppearance, "testAllShipShapes")
    runTest(TestMenuIntegration, "testGameStateTransitions")
    runTest(TestMenuIntegration, "testReturnToMenu")
    
    print(string.format("\nTest Summary: %d total, %d passed, %d failed", testCount, passCount, failCount))
    
    if failCount > 0 then
        os.exit(1)
    else
        print("All tests passed!")
        os.exit(0)
    end
end

return {
    TestGame = TestGame,
    TestPlayer = TestPlayer,
    TestItemSystem = TestItemSystem,
    TestSpaceStation = TestSpaceStation,
    TestSettings = TestSettings,
    TestShipAppearance = TestShipAppearance,
    TestMenuIntegration = TestMenuIntegration
}
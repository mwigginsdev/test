-- Sci-Fi Bullet Hell Game
-- Main entry point for LÖVE2D

local Game = require('src.game')

function love.load()
    love.window.setTitle("Sci-Fi Bullet Hell")
    love.window.setMode(1024, 768)
    
    Game:init()
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
end

function love.keypressed(key)
    Game:keypressed(key)
end

function love.keyreleased(key)
    Game:keyreleased(key)
end

function love.mousepressed(x, y, button)
    Game:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Game:mousereleased(x, y, button)
end
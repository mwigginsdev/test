-- Particle effects system

local ParticleManager = {}
ParticleManager.__index = ParticleManager

function ParticleManager:new()
    local manager = setmetatable({}, ParticleManager)
    
    manager.particles = {}
    
    return manager
end

function ParticleManager:createExplosion(x, y, color, size)
    size = size or 1
    color = color or {1, 0.5, 0}
    
    -- Create explosion particles
    for i = 1, 15 * size do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 200) * size
        local life = math.random(0.3, 0.8)
        
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = life,
            maxLife = life,
            color = {color[1], color[2], color[3]},
            size = math.random(2, 6) * size,
            type = 'explosion'
        })
    end
end

function ParticleManager:createTrail(x, y, color, direction)
    color = color or {0, 1, 1}
    
    table.insert(self.particles, {
        x = x,
        y = y,
        vx = -direction.x * 50 + math.random(-20, 20),
        vy = -direction.y * 50 + math.random(-20, 20),
        life = 0.3,
        maxLife = 0.3,
        color = {color[1], color[2], color[3]},
        size = 2,
        type = 'trail'
    })
end

function ParticleManager:update(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        
        particle.life = particle.life - dt
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Fade out particles
        if particle.type == 'explosion' then
            particle.vx = particle.vx * 0.98 -- Air resistance
            particle.vy = particle.vy * 0.98
        end
        
        if particle.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function ParticleManager:draw()
    for _, particle in ipairs(self.particles) do
        local alpha = particle.life / particle.maxLife
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle('fill', particle.x, particle.y, particle.size * alpha)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return ParticleManager
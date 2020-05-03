--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Kevin Velazquez
    katz_powa@hotmail.com 

    A simple powerup class, mostly the spawn and take logic
]]

Powerup = Class{}

function Powerup:init(index)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16
    self.opacity = 128
    self.forward = true --flip to know if opacity is going forward

    -- this will effectively be the color of our ball, and we will index
    -- our table of Quads relating to the global block texture using this
    self.index = index
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the powerup somewhere random
]]
function Powerup:spawn()
    self.x = math.random(0, VIRTUAL_WIDTH - self.width)
    self.y = VIRTUAL_HEIGHT - 32
end

function Powerup:update(dt)
    if self.forward then
        self.opacity = self.opacity + 100 * dt
        print(self.opacity)
        -- If it reaches full opacity
        if self.opacity > 255 then
            self.opacity = 255
            self.forward = false
        end
    else
        self.opacity = self.opacity - 200 * dt
        print(self.opacity)
        -- if it reaches a 48 opacity
        if self.opacity < 48 then
            self.opacity = 48
            self.forward = true
        end
    end
end

function Powerup:render()
    -- Taking into account the opacity
    love.graphics.setColor(255/255, 255/255, 255/255, self.opacity/255)
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.index], self.x, self.y)
    --Reset color
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
end
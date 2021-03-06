--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.powerupMeter = 0

    -- give ball random starting velocity
    self.balls[1].dx = math.random(2) == 1 and math.random(-200, -75) or math.random(75, 200)
    self.balls[1].dy = math.random(-65, -75)

    self.powerup = {}
    self.powerupActive = false

    self.opacity = 128
    self.forward = true --flip to know if opacity is going forward
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    
    for key, ball in pairs(self.balls) do
        ball:update(dt)
        
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy
            
            --
            -- tweak angle of bounce based on where it hits the paddle
            --
            
            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
                
                -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end
            
            gSounds['paddle-hit']:play()
        end
        
        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do
            
            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then
                
                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
                
                if not self.powerupActive then
                    self.powerupMeter = self.powerupMeter + brick.tier * 200 + brick.color * 25
                end
                
                -- trigger the brick's hit function, which removes it from play
                brick:hit()
                
                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()
                    
                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball
                    })
                end
                
                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --
                
                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end
                
                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end
                
                -- only allow colliding with one brick, for corners
                break
            end
        end
        
        -- if ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then
            --check which ball it is
            if #self.balls == 1 then
                self.health = self.health - 1
                gSounds['hurt']:play()
                
                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level
                    })
                end        
            else
                gSounds['hurt']:play()
                table.remove(self.balls, key)
            end
        end
    end
        
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    -- Update the powerup
    if self.powerupActive then
        self.powerup:update(dt)

        if self.powerup:collides(self.paddle) then            
            gSounds['recover']:play()

            -- Reset the powerup status
            self.powerup = {}
            self.powerupActive = false

            --Spawn another ball
            print("spawning another baaaall")
            local newBall = Ball()
            newBall.skin = math.random(7)
            newBall.x = self.paddle.x + (self.paddle.width / 2) - 4
            newBall.y = self.paddle.y - 8
            newBall.dx = math.random(2) == 1 and math.random(-200, -75) or math.random(75, 200)
            newBall.dy = math.random(-65, -75)
            table.insert(self.balls, newBall)
        end
    end
    
    -- check if the scores hits a certain range
    local powerupCeiling = 100
    
    --If the powerup meter has been filled
    if self.powerupMeter >= powerupCeiling and self.powerupActive == false then
        self.powerup = Powerup(9)
        self.powerup:spawn()

        --We need to check that the powerup is not on top the paddle
        while self.powerup:collides(self.paddle) do
            print("respawing powerup")
            self.powerup:spawn()
        end
        
        self.powerupActive = true
        self.powerupMeter = self.powerupMeter % powerupCeiling
    end
    
    -- opacity
    if #self.balls >= 8 then
        if self.forward then
            self.opacity = self.opacity + 400 * dt
            -- If it reaches full opacity
            if self.opacity > 255 then
                self.opacity = 255
                self.forward = false
            end
        else
            self.opacity = self.opacity - 400 * dt
            -- if it reaches a 48 opacity
            if self.opacity < 48 then
                self.opacity = 48
                self.forward = true
            end
        end
    end

    --Quit
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for key, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- Render if it is active
    if self.powerupActive then
        self.powerup:render()
    end

    --Render how many balls you got there

    love.graphics.setFont(gFonts['medium'])
    if #self.balls < 4 then
        love.graphics.setColor(255/255, 255/255, 255/255, 40/255)
        love.graphics.print('Balls:', VIRTUAL_WIDTH/2 - 18, 0)
        love.graphics.print(tostring(#self.balls), VIRTUAL_WIDTH/2 + 24, 0)
    elseif #self.balls < 8 then
        love.graphics.setColor(255/255, 180/255, 180/255, 120/255)
        love.graphics.print('A lot of balls:', VIRTUAL_WIDTH/2 - 72, 0)
        love.graphics.print(tostring(#self.balls), VIRTUAL_WIDTH/2 + 44, 0)
    else
        love.graphics.setColor(255/55, 50/255, 80/255, self.opacity/255)
        love.graphics.print('Too many balls!!!:', VIRTUAL_WIDTH/2 - 82, 0)
        love.graphics.print(tostring(#self.balls), VIRTUAL_WIDTH/2 + 58, 0)
    end
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)


    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end
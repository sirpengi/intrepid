camera = {x = 0, y = 0}
player = {x = 200, y = 200}
rate = 1
movement = {
    s = {x = 0, y = rate},
    w = {x = 0, y = -rate},
    d = {x = rate, y = 0},
    a = {x = -rate, y = 0}
}
depressed = {}
tSize = 35
visible = false
world = {}

function love.load()
    -- background
    love.graphics.setBackgroundColor(255, 255, 255)

    -- generate world
    for y = 1, 25 do
        world[y] = {}
        for x = 1, 25 do
            v = love.math.noise(x, y)
            if (v < 0.100) then world[y][x] = v end
        end
    end
end

function love.draw()
    for y in pairs(world) do
        for x in pairs(world[y]) do
            love.graphics.setColor(155, 155, 155)
            love.graphics.rectangle(
                "fill",
                x * tSize + camera.x,
                y * tSize + camera.y,
                tSize,
                tSize
            )
        end
    end
    love.graphics.setColor(50, 75, 100)
    love.graphics.rectangle(
        "fill",
        player.x + camera.x,
        player.y + camera.y,
        tSize,
        tSize
    )
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end

function love.update(dt)
    for key, value in pairs(depressed) do
        local _x, _y = player.x, player.y

        if movement[key] then
            player.x = player.x + movement[key].x
            player.y = player.y + movement[key].y
        end

        for y in pairs(world) do
            for x in pairs(world[y]) do
                if not (x * tSize >= player.x + tSize
                    or x * tSize + tSize <= player.x
                    or y * tSize >= player.y + tSize
                    or y * tSize + tSize <= player.y)
                then
                    if key == 'w' then
                        player.y = (y * tSize) + tSize
                    elseif key == 's' then
                        player.y = (y * tSize) - tSize
                    elseif key == 'a' then
                        player.x = (x * tSize) + tSize
                    elseif key == 'd' then
                        player.x = (x * tSize) - tSize
                    end
                end
            end
        end
    end

    camera.x = -player.x + (love.window.getWidth() / 2)
    camera.y = -player.y + (love.window.getHeight() / 2)
end

function love.keypressed(key, unicode)
    depressed[key] = true
end

function love.keyreleased(key, unicode)
    depressed[key] = nil
end

function love.run()

    if love.math then
        love.math.setRandomSeed(os.time())
    end

    if love.event then
        love.event.pump()
    end

    if love.load then love.load(arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0
    local updates = 1 / 60
    local accumulator = 0.0

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
                if e == "quit" then
                    if not love.quit or not love.quit() then
                        if love.audio then
                            love.audio.stop()
                        end
                        return
                    end
                end
                love.handlers[e](a,b,c,d)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        if dt > 0.25 then
            dt = 0.25
        end

        -- Update at fixed rate
        accumulator = accumulator + dt
        while accumulator >= updates do
            if love.update then love.update(dt) end
            accumulator = accumulator - updates
        end

        -- Render
        if love.window and love.graphics and love.window.isCreated() then
            love.graphics.clear()
            love.graphics.origin()
            if love.draw then love.draw() end
            love.graphics.present()
        end

        -- if love.timer then love.timer.sleep(0.001) end
    end

end

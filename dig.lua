--[[
if not turtle then
    print("Must run on a turtle!")
    return
end
--]]
local pretty = require("cc.pretty")
ppt = pretty.pretty_print


local size = ...
size = tonumber(size)

-- Default forward
local dirForward = vector.new(1,0,0)
-- Default starting position
local pos = vector.new(0,0,0)
local home = vector.new(0,0,0)

-- +X is pointed in the front face of the turtle
-- This is the direction the turtle will move forawrd
-- +Y is perpindicular to the right of +X
-- +Z is the direction the turtle will move up

local function sign(x)
    return x>0 and 1 or x<0 and -1 or 0
end

UnitVec = {}
UnitVec.z = vector.new(0,0,1)
UnitVec.y = vector.new(0,1,0)
UnitVec.x = vector.new(1,0,1)

local function rot90(vec, ax)
    if ax == "x" then
        return vector.new(vec.x,-vec.z,vec.y)
    elseif ax == "y" then
        return vector.new(vec.z,vec.y,-vec.x)
    elseif ax == "z" then
        return vector.new(-vec.y,vec.x,vec.z)
    else
        error("Unkown axis")
    end
end

local function rotn90(vec, ax)
    if ax == "x" then
        return vector.new(vec.x,vec.z,-vec.y)
    elseif ax == "y" then
        return vector,new(-vec.z,vec.y,vec.x)
    elseif ax == "z" then
        return vector.new(vec.y,-vec.x,vec.z)
    else
        error("Unknown axis")
    end
end

local function forward()
    pos = pos + dirForward
    turtle.forward()
end

local function back()
    pos = pos - dirForward
    turtle.back()
end

local function up()
    pos = pos + UnitVec.z
    turtle.up()
end

local function down()
    pos = pos - UnitVec.z
    turtle.down()
end

local function turnLeft()
    dirForward = rotn90(dirForward, "z")
    turtle.turnLeft()
end

local function turnRight()
    dirForward = rot90(dirForward, "z")
    turtle.turnRight()
end

--Sign is the sign of the X direction
local function faceX(xsign)
    if dirForward.x == 0 then
        if dirForward.y == -1*xsign then
            turnRight()
        elseif dirForward.y == 1*xsign then
            turnLeft()
        end
    elseif dirForward.x == -1*xsign then
        turnRight()
        turnRight()
    end
end

local function faceY(ysign)
    if dirForward.y == 0 then
        if dirForward.x == 1*ysign then
            turnRight()
        elseif dirForward.x == -1*ysign then
            turnLeft()
        end
    elseif dirForward.y == -1*ysign then
        turnRight()
        turnRight()
    end
end

local function checkInventory()
    local openSlots = 16
    local totalItems = 0
    
    local item = 0
    for n=1,16 do
        item = turtle.getItemCount(n)
        if item ~= 0 then
            totalItems = totalItems + item
            openSlots = openSlots - 1
        end
    end
    
    return openSlots, totalItems
end

local function emptyInventory()
    local selected = turtle.getSelectedSlot()
    local unloaded = 0
    for n=1,16 do
        turtle.select(n)
        turtle.drop()
    end
    turtle.select(selected)
end

local function goToEmptyInventory()
    local prevPos = vector.new(pos.x, pos.y, pos.z)
    local prevDirForward = vector.new(dirForward.x, dirForward.y, dirForward.z)
    
    goToPos(home.x, home.y, home.z)
    faceX(-1)
    
    emptyInventory()
    
    goToPos(prevPos.x, prevPos.y, prevPos.z)    
    if prevDirForward.x == 0 then
        faceY(prevDirForward.y)
    else
        faceX(prevDirForward.x)
    end
end

local function tryInv()
    local slots = checkInventory()
    if slots == 0 then
        print("Returning to empty inventory")
        goToEmptyInventory()
    end
end

local function tryDown()
    tryInv()
    if turtle.detectDown() then
        if turtle.digDown() then
            down()
            return true
        else
            return false
        end
    else
        down()
        return true
    end
end

local function tryUp()
    tryInv()
    if turtle.detectUp() then
        if turtle.digUp() then
            up()
            return true
        else
            return false
        end
    else
        up()
        return true
    end
end
 
local function tryForward()
    tryInv()
    if turtle.dig() then
        forward()
        return true
    else
        if not turtle.detect() then
            forward()
            return true
        else
            return false
        end
    end
    return false
end

local function goToPos(x,y,z)
    delta = vector.new(x,y,z)-pos
    
    if delta == vector.new(0,0,0) then
        return
    end
    
    if delta.x ~= 0 then
        faceX(sign(delta.x))
        repeat
            tryForward()
        until pos.x == x
    end
    
    if delta.y ~= 0 then
        faceY(sign(delta.y))
        repeat
            tryForward()
        until pos.y == y
    end
    
    if delta.z > 0 then
        repeat
            tryUp()
        until pos.z == z
    elseif delta.z < 0 then
        repeat
            tryDown()
        until pos.z == z
    end
end


local function excavateTriLayer()
    local digBelow = true
    -- Dig down two layers
    local layers = 0    
    while (layers~=2 and tryDown()) do
        layers = layers + 1
    end
    if turtle.detectDown() then
        if not turtle.digDown() then
            digBelow = false        
        end
    end

    local offset = 0
    for yn=1,size do
        for xn=1, size-1 do
            -- Try to move forwards
            -- If we can't break out
            if not tryForward() then
                done = true
                break
            end
            turtle.digUp()
            turtle.digDown()
        end
        if done then
            print("break")
            break
        end
            
        if yn<size then
            if ((yn+offset)%2 == 1) then
                turnRight()
                if not tryForward() then
                    done = true
                    break
                end
                turnRight()
            else
                turnLeft()
                if not tryForward() then
                    done = true
                    break
                end
                turnLeft()
            end
            turtle.digUp()
            turtle.digDown()
        end
    end
    if done then
        return false
    end
    
    if size > 1 then
        if (size % 2) == 0 then
            turnRight()
        else
            if offset == 0 then
                turnLeft()
                turnLeft()
            else
                turnRight()
                turnRight()
            end
            offset = 1 - offset
        end
    end 
end

local status = true
while status do
    status = excavateTriLayer()
    status = tryDown()
end

goToPos(home.x, home.y, home.z)
faceX(-1)
emptyInventory()
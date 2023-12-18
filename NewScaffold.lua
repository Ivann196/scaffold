http.load("https://raw.githubusercontent.com/CluePortal/ZarScriptHelper/main/MoreFunctions.lua")
local blockX, blockY, blockZ, blockFacing
local hitX, hitY, hitZ
local oldSlot
local swapped = false
local blockYaw, blockPitch
local lastMS = client.time()
local offGroundTicks = 0
local swapdelay = 0

local directions = {
    { facing = 1, x = 0, y = -1, z = 0 },
    { facing = 2, x = 0, y = 1, z = 0 },
    { facing = 3, x = 0, y = 0, z = -1 },
    { facing = 4, x = 0, y = 0, z = 1 },
    { facing = 5, x = -1, y = 0, z = 0 },
    { facing = 6, x = 1, y = 0, z = 0 }
}

function wrapAngleTo180(value)
    value = value % 360.0;
    if (value >= 180.0) then
        value = value - 360.0;
    end
    if (value < -180.0) then
        value = value + 360.0;
    end
    return value;
end

function grabBlockSlot()
    local slot = -1
    local highestStack = -1
    local didGetHotbar = false
    for i = 1, 9 do
        local name = player.inventory.item_information(35 + i)
        local size = player.inventory.get_item_stack(35 + i)
        if size ~= nil and name ~= nil and string.match(name, "tile") and size > 0 and canPlaceBlock(name) then
            if size > highestStack then
                highestStack = size
                slot = i
                if slot == getLastHotbar then
                    didGetHotbar = true
                end
            end
        end
    end
    return slot
end

local invalidBlocks = {
    "tile.sand",
    "tile.gravel",
    "tile.anvil",
    "tile.chest",
    "tile.enderChest",
    "tile.anvil",
    "tile.dropper",
    "tile.ladder",
    "tile.dispenser",
    "Rail",
    "tile.rail",
    "tile.sapling",
    "tile.web",
    "tile.workbench",
    "tile.furnace",
    "tile.cactus",
    "tile.jukebox",
    "tile.fenceIron",
    "tile.thinGlass",
    "Gate",
    "tile.doublePlant",
    "Fence",
    "fence",
    "gate",
    "tile.deadbush",
    "tile.flower2",
    "tile.musicBlock",
    "tile.mushroom",
    "slab",
    "tile.torch",
    "tile.notGate",
    "tile.lever",
    "tile.button",
    "pressurePlate",
    "weightedPlate",
    "stairs",
    "tile.hopper",
    "tile.endPortalFrame",
    "tile.enchantmentTable",
    "tile.tripWireSource",
    "tile.waterlily",
    "tile.vine",
    "tile.daylightDetector",
    "tile.woolCarpet",
    "tile.trapdoor",
    "tile.ironTrapdoor",
    "tile.banner"
}

function diagonal()
    local mx, my, mz = player.motion()
    return (math.abs(mx) > 0.05 and math.abs(mz) > 0.05)
end

function canPlaceBlock(heldItemName)
    if heldItemName ~= nil then
        for i = 1, #invalidBlocks do
            local block = invalidBlocks[i]
            if string.find(heldItemName, block) or heldItemName == "tile.clay" then
                return false
            end
        end
    end
    return true
end

function offSetPos(x, y, z, facing) 
    if facing == 1 then
        return x, y - 1, z
    elseif facing == 2 then
        return x, y + 1, z
    elseif facing == 3 then
        return x, y, z - 1
    elseif facing == 4 then
        return x, y, z + 1
    elseif facing == 5 then
        return x - 1, y, z
    elseif facing == 6 then
        return x + 1, y, z
    end
end

function toOpposite(facing)
    if facing == 1 then
        return 2
    elseif facing == 2 then
        return 1
    elseif facing == 3 then
        return 4
    elseif facing == 4 then
        return 3
    elseif facing == 5 then
        return 6
    elseif facing == 6 then
        return 5
    end
end

function getEyePosition()
    local x, y, z = player.position()
    return x, y + player.eye_height(), z
end

local lastX, lastY, lastZ, lastFacing

local gticks = 0

function findBlocks()
    local enumFacings = {
        down = 1,
        up = 2,
        north = 3,
        south = 4,
        west = 5,
        east = 6
    }
    local rawX, rawY, rawZ = player.position()
    local x, y, z = math.floor(rawX), math.floor(rawY), math.floor(rawZ)
    if world.block(x, y - 1, z) == "tile.air" or world.block(x, y - 1, z) == "tile.fire" then
        for _, enumFacing in pairs(enumFacings) do
            if enumFacing ~= 2 then
                local offSetX, offSetY, offSetZ = offSetPos(x, y - 1, z, enumFacing)
                if world.block(offSetX, offSetY, offSetZ) ~= "tile.air" then
                    return offSetX, offSetY, offSetZ, toOpposite(enumFacing)
                end
            end
        end
        for _, enumFacing in pairs(enumFacings) do
            if enumFacing ~= 2 then
                local offSetX1, offSetY1, offSetZ1 = offSetPos(x, y - 1, z, enumFacing)
                if world.block(offSetX1, offSetY1, offSetZ1) == "tile.air" or world.block(offSetX1, offSetY1, offSetZ1) == "tile.fire" then
                    for _, enumFacing2 in pairs(enumFacings) do
                        if enumFacing2 ~= 2 then
                            local offSetX2, offSetY2, offSetZ2 = offSetPos(offSetX1, offSetY1, offSetZ1, enumFacing2)
                            if world.block(offSetX2, offSetY2, offSetZ2) ~= "tile.air" then
                                return offSetX2, offSetY2, offSetZ2, toOpposite(enumFacing2)
                            end
                        end
                    end
                end
            end
        end
    end
end

function getRotationsToPos(sX, sY, sZ, eX, eY, eZ)
    local d0 = eX - sX
    local d1 = eY - sY
    local d2 = eZ - sZ
    local d3 = math.sqrt(d0 * d0 + d2 * d2)
    local f = (math.atan2(d2, d0) * 180 / math.pi) - 90
    local f1 = (-(math.atan2(d1, d3) * 180 / math.pi))
    return f, f1
end

function getDirection()
    local yaw, pitch = player.angles()
	local forward, strafing = player.strafe()
    if forward == 0 and strafing == 0 then
        return yaw
    end
    local strafingYaw
    local reversed = forward < 0
    if forward > 0 then
        strafingYaw = 90 * 0.5
    elseif reversed then
        strafingYaw = 90 * -0.5
    else
        strafingYaw = 90 * 1
    end
    if reversed then
        yaw = yaw + 180
    end
    
    if strafing > 0 then
        yaw = yaw - strafingYaw
    elseif strafing < 0 then
        yaw = yaw + strafingYaw
    end
    return yaw
end

function getCoord(facing, coord)
    for _, dir in ipairs(directions) do
        if dir.facing == facing then
            if coord == "x" then
                return dir.x
            elseif coord == "y" then
                return dir.y
            elseif coord == "z" then
                return dir.z
            end
        end
    end
end

function getTotalBlocks()
    if client.gui_name() == "none" then   
        local total_blocks = 0
        for slot_id = 5, 44 do
            local name = player.inventory.item_information(slot_id)
            if name ~= nil and string.match(name, "tile") and canPlaceBlock(name) then
                local item_count = player.inventory.get_item_stack(slot_id)
                total_blocks = total_blocks + item_count
            end
        end
        return total_blocks
    end
end

function renderBlockOutline(event, x, y, z)
	local minX, minY, minZ, maxX, maxY, maxZ = renderHelper.getBlockBoundingBox(x, y, z)
	renderHelper.renderOutline(minX, minY, minZ, maxX, maxY, maxZ, event, 225, 37, 70, 255, 5)
end

function place()
    blockX, blockY, blockZ, blockFacing = findBlocks()
    if blockX == nil or blockY == nil or blockZ == nil or blockFacing == nil then return end
    local x,y,z = player.position()
    player.ray_cast(blockX, blockY, blockZ, blockFacing)
    player.place_block(player.held_item_slot(), blockX, blockY, blockZ, blockFacing, (blockX + 0.5) + getCoord(blockFacing, "x") * 0.5, (blockY + 0.5) + getCoord(blockFacing, "y") * 0.5, (blockZ + 0.5) + getCoord(blockFacing, "z") * 0.5)
    if module_manager.option("Scaffold2", "Client-Swing") then
        player.swing_item()
    else
        player.send_packet(0x0A)
    end
end

module_manager.register("Scaffold2", {
    on_pre_update = function()
        if module_manager.option("Scaffold2", "Hurttime-Boost") and player.hurt_time() > 8 then
            player.set_speed(0.26)
            ht = true
        elseif ht and module_manager.option("Scaffold2", "Hurttime-Boost") and player.hurt_time() <= 0 and player.on_ground() then
            player.set_speed(-0.127)
            ht = false
        end
        if module_manager.option("Scaffold2", "Disable-Tower-On-Dmg") and player.hurt_time() > 0 then
            groundcheck = true
            gticks = 0
            offground = false
            ground = true
        end
        local mx, my, mz = player.motion()
        if player.sprinting() then
            player.set_sprinting(false)
        end
        local slot = grabBlockSlot()
        if slot == -1 then return end
        if swap then
            swapdelay = swapdelay + 1
        end
        if swapdelay > 2 then
            player.set_held_item_slot(slot - 2)
            swapped = true
            swapdelay = 0
        end
        if player.on_ground() then
            player.set_motion(mx * 0.97, my, mz * 0.97)
        end
        blockX, blockY, blockZ, blockFacing = findBlocks()
        if blockX == nil or blockY == nil or blockZ == nil or blockFacing == nil then return end
        lastX = blockX
        lastY = blockY
        lastZ = blockZ
        lastFacing = blockFacing
        if not player.on_ground() then
            offGroundTicks = offGroundTicks + 1
        else
            offGroundTicks = 0
        end
        place()
        place()
    end,

    on_pre_motion = function(event)
        if player.on_ground() then
            groundcheck = true
            gticks = 0
            offground = false
            ground = true
        end
        if groundcheck and not player.on_ground() then
            offground = true
        end
        if offground then
            gticks = gticks + 1
        end
        if gticks == 3 then
            ground = false
            groundcheck = false
        end
        local name = player.inventory.item_information(35 + player.held_item_slot())
        if module_manager.is_module_on("Scaffold2") and input.is_key_down(57) and input.is_key_down(17) and player.on_ground() and name ~= nil and string.match(name, 'tile') then
            player.set_speed(0.12)
        end
        if module_manager.is_module_on("Scaffold2") and input.is_key_down(57) and input.is_key_down(17) and player.on_ground() and name ~= nil and string.match(name, 'tile') then
            player.jump()
        end
        downmotion = module_manager.option('Scaffold2', 'Tower-Motion')
        if module_manager.is_module_on("Scaffold2") and input.is_key_down(57) and input.is_key_down(17) and not ground then
            local mx,my,mz = player.motion()
            player.set_motion(mx, -downmotion, mz)
        end
        event.yaw = event.yaw - 180
        if not input.is_key_down(57) then
            event.pitch = 77
        else
            event.pitch = 74
        end
        return event
    end,

    on_enable = function()
        local yaw, pitch = player.angles()
        oldSlot = player.held_item_slot()
        if not module_manager.is_module_on("Safewalk") then
            player.message('.safewalk')
        end
        local slot = grabBlockSlot()
        if slot == -1 then return end
        player.set_held_item_slot(slot - 2)
        swapped = true
    end,

    on_disable = function()
        if swapped then
            player.set_held_item_slot(oldSlot - 2)
            swapped = false
        end
        if module_manager.is_module_on("Safewalk") then
            player.message('.safewalk')
        end
        swapdelay = 0
    end,

    on_send_packet = function(t)
        if t.packet_id == 0x08 then
            swapdelay = 0
            swap = true
        end
    end,

    on_render_screen = function(t)
        if client.gui_name() == "none" and module_manager.option("Scaffold2", "Show Blocks") then
            if getTotalBlocks() == 1 then
                more = ""
            else
                more = "s"
            end
            render.scale(0.9)
            render.string_shadow(getTotalBlocks() .. " block" .. more, (t.width/2 + 8)/0.9, (t.height/2 - 2)/0.9, 255, 255, 255, 255)
            render.scale(1/0.9)
        end
        if lastX ~= nil then
            local x, y, z = offSetPos(lastX, lastY, lastZ, lastFacing)
            --renderBlockOutline(t, x, y, z)
        end
    end
})

module_manager.register_boolean("Scaffold2", "Show Blocks", false)
module_manager.register_boolean("Scaffold2", "Client-Swing", false)
module_manager.register_number('Scaffold2', 'Tower-Motion', 0.01, 0.7, 0.1)
--module_manager.register_boolean("Scaffold2", "Hurttime-Boost", false)
module_manager.register_boolean("Scaffold2", "Disable-Tower-On-Dmg", true)
-- base by unloged, edited by jd
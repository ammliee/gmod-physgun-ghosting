-- Physgun Ghosting
-- Readable replacement for the original gm_blueprints v1.4 output.
-- Held entities pass through players and props, but still collide with the world.

if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    -- Userinfo lets the server read each player's preference with GetInfoNum.
    CreateClientConVar(
        "ghost_when_physgunning", "1", true, true,
        "Disable collisions with players and props while using the physgun.",
        0, 1
    )

    return
end

local allowGhosting = CreateConVar(
    "allow_physgun_ghosting", "1", FCVAR_ARCHIVE,
    "Allow physgun ghosting on this server.",
    0, 1
)

hook.Add("OnPhysgunPickup", "PhysgunGhosting_Pickup", function(player, entity)
    if not IsValid(player) or not IsValid(entity) then return end
    if not allowGhosting:GetBool() then return end
    if player:GetInfoNum("ghost_when_physgunning", 1) == 0 then return end

    -- Store the original group per entity so different players' props cannot
    -- overwrite one another's state. Entity fields also survive Lua auto-refresh.
    if entity.PhysgunGhostingOriginalCollisionGroup == nil then
        entity.PhysgunGhostingOriginalCollisionGroup = entity:GetCollisionGroup()
    end

    entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
end)

hook.Add("PhysgunDrop", "PhysgunGhosting_Drop", function(player, entity)
    if not IsValid(entity) then return end

    local originalCollisionGroup = entity.PhysgunGhostingOriginalCollisionGroup
    if originalCollisionGroup == nil then return end

    -- Always restore entities we ghosted, even if a convar changed while held.
    entity:SetCollisionGroup(originalCollisionGroup)
    entity.PhysgunGhostingOriginalCollisionGroup = nil
end)

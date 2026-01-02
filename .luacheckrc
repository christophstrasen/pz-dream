std = "lua51"  -- Lua 5.1 (Project Zomboid Build 42 / Kahlua)

-- Project Zomboid globals referenced by examples/tests.
globals = {
    -- Core game functions
    "sendServerCommand",
    "getPlayer",
    "Events",
    "getCell",
    "getGameTime",
    "getSoundManager",
    "ZombRand",
    "print",
    "isServer",
    "isClient",

    -- World/sprites
    "getWorld",
    "getSprite",

    -- IsoWorld and grid management
    "IsoGridSquare",
    "IsoWorld",
    "IsoCell",
    "IsoChunk",
    "IsoMetaGrid",
    "IsoMetaCell",

    -- Special objects
    "IsoObject",
}

ignore = {
    "211", -- Unused variable
    "212"  -- Unused argument
}

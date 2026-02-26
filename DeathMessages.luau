local DeathMessages = {}

DeathMessages.Dictionary = {
    "%s made a generational fumble",
    "%s's mom walked in",
    "It's all %s's fault!",
    "BREAKING NEWS: %s sentenced to perpetual prison.",
    "%s stepped on a LEGO piece",
}

function DeathMessages.Random(player: Player)
    return DeathMessages.Dictionary[math.random(1, #DeathMessages.Dictionary)]:format(player.Name)
end

return DeathMessages
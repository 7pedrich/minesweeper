local Players = game:GetService("Players")
local PlayerFunctions = {}

function PlayerFunctions.setPlayerPosition(player: Player, position : Vector3)
    local character = player.Character or workspace[player.Name]
    assert(character, "Player has no character loaded.")

    local humanoidRootPart : Part = character:FindFirstChild("HumanoidRootPart")

    humanoidRootPart.Position = position
end

function PlayerFunctions.kill(player: Player)
    local character = player.Character
    local humanoid = character.Humanoid

    humanoid.Health = 0
end

function PlayerFunctions.increaseWinCount(player: Player)
    local leaderstats = player:WaitForChild("leaderstats")
    leaderstats.Wins.Value += 1
end

function PlayerFunctions.forAll(actionName: string, ...)
    for _, player in Players:GetPlayers() do
        PlayerFunctions[actionName](player, ...)
    end
end

function PlayerFunctions.forGroup(actionName: string, group: {Player}, ...)
    for _, player in group do
        PlayerFunctions[actionName](player, ...)
    end
end

return PlayerFunctions
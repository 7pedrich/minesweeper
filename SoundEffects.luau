local SoundService = game:GetService("SoundService")
local SoundEffects = { }

function SoundEffects.playSound(soundName: string)
    assert(SoundService.Effects:FindFirstChild(soundName), "Sound Effect Doesn't Exist")
    local Effect = SoundService.Effects:FindFirstChild(soundName)
    
    Effect:Play()
end

function SoundEffects.playSoundOnPart(soundName: string, part: Part)
    assert(SoundService.Effects:FindFirstChild(soundName), "Sound Effect Doesn't Exist")
    local Effect = SoundService.Effects:FindFirstChild(soundName)

    Effect:Clone().Parent = part
    Effect:Play()
end

return SoundEffects
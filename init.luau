local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Remote = ReplicatedStorage.Remote

local Minesweeper = {}
Minesweeper.__index = Minesweeper

local _debugging = true

-- dependencies
local Grid = require(script:FindFirstChild("Grid"))
local __repr__ = require(3148021300)
local SoundEffects = require(Modules.SoundEffects)
local PlayerControl = require(Modules.PlayerControl)
local DeathMessages = require(Modules.DeathMessages)

local TextColors = {
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 22, 125),
	Color3.fromRGB(124, 59, 5),
	Color3.fromRGB(7, 197, 188),
	Color3.fromRGB(0, 0, 0),
	Color3.fromRGB(133, 133, 133)
}

function Minesweeper.new(participatingPlayers: {Player}, originPosition: Vector3, gridSizeX: number, gridSizeY: number, bombChance: number) : typeof(setmetatable({}, Minesweeper))
	if workspace:FindFirstChild("Minesweeper") then
		return error("You can't make another game during an active one")
	end

	local self = setmetatable({}, Minesweeper)

	local gameGrid = Grid.new(gridSizeX, gridSizeY, bombChance)
	local generatedGrid = gameGrid:_generate()

	local gameFolder = Instance.new("Folder", workspace)
	gameFolder.Name = "Minesweeper"

	self.participatingPlayers = participatingPlayers
	self.gridSizeX = gridSizeX
	self.gridSizeY = gridSizeY
	self.bombChance = bombChance
	self.generatedGrid = generatedGrid
	self.gameGrid = gameGrid
	self.gameFolder = workspace.Minesweeper
	self.originPosition = originPosition
	self.flagPlacements = gameGrid:_getEmptyGrid()
	self.status = "Ongoing"
	self.connections = {}
	self.playerConnections = {}

	print(self.participatingPlayers)

	if #self.participatingPlayers == 0 then
		self:_terminate()
	end

	for index, value in generatedGrid do
		local adjustedIndex = index - 1  -- Convert to 0-based
		local xPos = adjustedIndex % self.gridSizeX
		local yPos = math.floor(adjustedIndex / self.gridSizeX)

		self:_createPart(index, xPos, yPos)
	end

	repeat task.wait() until workspace:FindFirstChild("Minesweeper")
	self:_addControls()
	self:_updateGameStatusValue()

	task.wait(5)
	self:_spawnPlayers()
	task.wait(1)
	for _, player in self.participatingPlayers do
		local character = player.Character
		local humanoid = character:WaitForChild("Humanoid")

		self.playerConnections[#self.playerConnections + 1] = humanoid.Died:Connect(function()
			self.participatingPlayers[table.find(self.participatingPlayers, player)] = nil
			if #self.participatingPlayers == 0 then
				self:_terminate()
			end
		end)
		self.playerConnections[#self.playerConnections + 1] = player.OnTeleport:Connect(function()
			self.participatingPlayers[table.find(self.participatingPlayers, player)] = nil
		end)
	end

	return self
end

function Minesweeper:_updateGameStatusValue()
	workspace.GameStatus.Value = self.status
end

function Minesweeper:_terminate()
	self:_cleanup("Lost")
	task.wait(2)
	self:_destroy()
end

function Minesweeper:_addPartText(Part: Part) : TextLabel
	assert(Part:FindFirstChild("SurfaceGui"), "The surfaceGui doesn't exist in the part")

	local ResultTextLabel = Instance.new("TextLabel", Part:FindFirstChild("SurfaceGui"))

	ResultTextLabel.Size = UDim2.new(1, 0, 1, 0)
	ResultTextLabel.AnchorPoint = Vector2.new(.5, .5)
	ResultTextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	ResultTextLabel.Name = "Result"
	ResultTextLabel.TextScaled = true
	ResultTextLabel.RichText = true
	ResultTextLabel.BackgroundTransparency = 1
	ResultTextLabel.Text = ""
	ResultTextLabel.Font = Enum.Font.Arcade

	return ResultTextLabel
end

function Minesweeper:_flagPlacementCheck()
	if self.flagPlacements == self.generatedGrid then
		self:_cleanup("Won")

		for _, part in self.gameFolder do
			part.BrickColor = BrickColor.Green()
		end
	end
end

function Minesweeper:_createPart(index, xPos, yPos)
	local part = Instance.new("Part", self.gameFolder)
	part.Size = Vector3.new(4, 1, 4)
	part.Position = Vector3.new(xPos * 4, 10, yPos * 4) + self.originPosition
	part.Name = index
	part.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	part.Anchored = true
	part.Color = if index % 2 == 1 then Color3.fromRGB(75, 173, 62) else Color3.fromRGB(99, 228, 82)

	local surfaceGui = Instance.new("SurfaceGui", part)
	surfaceGui.Face = Enum.NormalId.Top

	if self.generatedGrid[index] == 1 then
		CollectionService:AddTag(part, "Bomb")
	end
end

function Minesweeper:_getPartFromIndex(index: number)
	return workspace.Minesweeper[tostring(index)]
end

function Minesweeper:_isPartRevealed(index: number)
	return table.find(Minesweeper:_getPartFromIndex(index):GetTags(), "Revealed") ~= nil
end

function Minesweeper:_revealBomb(part: Part)
	part.BrickColor = BrickColor.Black()
	local Explosion = Instance.new("Explosion")
	Explosion.Position = part.Position
	Explosion.BlastPressure = 1
	Explosion.BlastRadius = 2
	Explosion.ExplosionType = Enum.ExplosionType.NoCraters
	Explosion.DestroyJointRadiusPercent = 0
	Explosion.Parent = part
end

function Minesweeper:_getBombCount()
	local count = 0
	for i, v in workspace.Minesweeper:GetChildren() do
		if table.find(v:GetTags(), "Bomb") then
			count += 1
		end
	end

	return count
end

function Minesweeper:_cascadeExplosion()
	for i, v in workspace.Minesweeper:GetChildren() do
		if table.find(v:GetTags(), "Bomb") then
			self:_revealBomb(v)
			task.wait(1 / self:_getBombCount())
		end
	end
end

function Minesweeper:_revealPart(Part: Part, gridIndex: number, character: Model)
	if Minesweeper:_isPartRevealed(gridIndex) then return end

	local SurfaceGui = Part:FindFirstChild("SurfaceGui")
	local Label = SurfaceGui:FindFirstChild("Result")

	local player = Players:GetPlayerFromCharacter(character)
	Part:AddTag("Revealed")

	if self.generatedGrid[gridIndex] == 1 then
		Remote.DeathMessage:FireAllClients(
			DeathMessages.Random(player)
		)

		local Humanoid = character:FindFirstChildWhichIsA("Humanoid")
		Humanoid.WalkSpeed = 0

		Part.BrickColor = BrickColor.Red()

		SoundEffects.playSoundOnPart("Explosion", Part)
		local Explosion = Instance.new("Explosion")
		Explosion.Position = Part.Position
		Explosion.BlastRadius = 2
		Explosion.BlastPressure = 1
		Explosion.ExplosionType = Enum.ExplosionType.NoCraters
		Explosion.DestroyJointRadiusPercent = 0
		Explosion.Parent = Part

		task.wait(1)

		self:_cleanup("Lost")
		Minesweeper:_cascadeExplosion()

		task.wait(3)

		self:_destroy()
	else
		local nearbyBombs = self.gameGrid:_nearbyBombAmount(gridIndex)
		Label.TextColor3 = TextColors[nearbyBombs] or Color3.fromRGB(255, 255, 255)
		Label.Text = (if nearbyBombs ~= 0 then nearbyBombs else "")
		Part.Color = if nearbyBombs ~= 0 then Color3.fromRGB(236, 255, 62) else Color3.fromRGB(239, 253, 110)

		local ClickDetector = Part:FindFirstChild("ClickDetector")
		ClickDetector.MaxActivationDistance = 0

		if nearbyBombs == 0 then
			local emptyNeighbouringCells = self.gameGrid:_getNeighbors(gridIndex)

			for _, index in emptyNeighbouringCells do
				if not self:_isPartRevealed(index) then
					self:_revealPart(self:_getPartFromIndex(index), index)
				end
			end
		end
	end
end

function Minesweeper:_isEmptyCell(Part: Part)
	local gridIndex = tonumber(Part.Name)
	return self.generatedGrid[gridIndex] == 0
end

function Minesweeper:_getRandomSafePosition()
	local safePoints = {}
	for i, v in self.generatedGrid do
		if self.gameGrid:_nearbyBombAmount(i) == 0 and v ~= 1 then
			safePoints[#safePoints + 1] = i
		end
	end

	local chosenSafePoint = safePoints[math.random(1, #safePoints)]
	local part = workspace.Minesweeper[tostring(chosenSafePoint)]

	return part.Position + Vector3.new(0, 10, 0)
end

function Minesweeper:_spawnPlayers()
	for _, player in self.participatingPlayers do
		local safePoint = self:_getRandomSafePosition()
		PlayerControl.setPlayerPosition(player, safePoint)
	end
end

function Minesweeper:_addControls() : ()
	assert(workspace:FindFirstChild("Minesweeper"), "Create the game first before calling this.")

	repeat task.wait() until #self.gameFolder:GetChildren() == self.gridSizeX * self.gridSizeY

	for _, Part in workspace.Minesweeper:GetChildren() do
		local ClickDetector = Instance.new("ClickDetector", Part)

		local Label = self:_addPartText(Part)
		local gridIndex = tonumber(Part.Name)

		self.connections[gridIndex] = Part.Touched:Connect(function(otherPart)
			if otherPart.Parent:FindFirstChildWhichIsA("Humanoid") then
				if self.flagPlacements[gridIndex] == 1 then
				else
					self:_revealPart(Part, gridIndex, otherPart.Parent)
				end
			end
		end)
		self.connections[gridIndex + 1] = ClickDetector.MouseClick:Connect(function()
			if Minesweeper:_isPartRevealed(gridIndex) then return end

			if self.flagPlacements[gridIndex] == 1 then
				SoundEffects.playSoundOnPart("FlagRemoval", Part)
				Label.Text = ""
				self.flagPlacements[gridIndex] = 0
			else
				SoundEffects.playSoundOnPart("Flag", Part)
				Label.Text = "🚩"
				self.flagPlacements[gridIndex] = 1
			end

			self:_flagPlacementCheck()
		end)
	end
end

function Minesweeper:_cleanup(result)
	for _, part in workspace.Minesweeper:GetChildren() do
		part.TouchInterest:Destroy()
	end
	for _, connection : RBXScriptConnection in self.connections do
		connection:Disconnect()
	end
	for _, connection : RBXScriptConnection in self.playerConnections do
		connection:Disconnect()
	end
	self.status = result
	self:_updateGameStatusValue()
end

function Minesweeper:_destroy()
	self.gameFolder:Destroy()
	Remote.GameEnded:Fire(self.status)
end

return Minesweeper
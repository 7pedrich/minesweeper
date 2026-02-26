local Grid = {}
Grid.__index = Grid

-- bomb chance should be a number from 0 to 100
function Grid.new(gridSizeX: number,  gridSizeY: number, bombChance: number) : typeof(setmetatable({}, Grid))
    local self = setmetatable({}, Grid)

    self.gridSizeX = gridSizeX
    self.gridSizeY = gridSizeY
    self.bombChance = bombChance or 12

    return self 
end

function Grid:_generate() : {number}
    local tbl = {}
    
    for i = 1, self.gridSizeX * self.gridSizeY do
        local rng = math.random(0, 100)
        tbl[#tbl + 1] = if rng <= self.bombChance then 1 else 0
    end

    self.generatedGrid = tbl
    return tbl
end

function Grid:_nearbyBombAmount(index: number) : number
    assert(self.generatedGrid, "Generate a grid before calling this")
    
    local x = (index - 1) % self.gridSizeX + 1
    local y = math.floor((index - 1) / self.gridSizeX) + 1
    
    local offsets = { 
        {1, 0}, {-1, 0}, {0, 1}, {0, -1},
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    }

    local bombCount = 0

    for _, offset in ipairs(offsets) do
        local newX = x + offset[1]
        local newY = y + offset[2]
        
        if newX >= 1 and newX <= self.gridSizeX and newY >= 1 and newY <= self.gridSizeY then
            local newIndex = (newY - 1) * self.gridSizeX + newX
            if self.generatedGrid[newIndex] == 1 then
                bombCount = bombCount + 1
            end
        end
    end

    return bombCount
end

function Grid:_getNeighbors(index: number) : {}
    local neighbors = {}
    local x = (index - 1) % self.gridSizeX + 1
    local y = math.floor((index - 1) / self.gridSizeX) + 1
    
    local offsets = { 
        {1, 0}, {-1, 0}, {0, 1}, {0, -1},
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1}
    }

    for idx, offset in ipairs(offsets) do
        local newX = x + offset[1]
        local newY = y + offset[2]
        
        if newX >= 1 and newX <= self.gridSizeX and newY >= 1 and newY <= self.gridSizeY then
            neighbors[idx] = (newY - 1) * self.gridSizeX + newX
        else
            neighbors[idx] = nil
        end
    end

    return neighbors
end

function Grid:_getEmptyGrid()
    local grid = {}

    for i = 1, self.gridSizeX * self.gridSizeY do
        grid[#grid+1] = 0
    end
    
    return grid
end

return Grid
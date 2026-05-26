-- A dynamic, center-expanding spectrum visualizer for cliamp,
-- featuring discrete bars with an intensity-based color gradient

local p = plugin.register({ name = "Nightrider", type = "visualizer" })

local ESC = string.char(27)
local RESET = ESC .. "[0m"
local SPACE_CHAR = " "
-- K.I.T.T. Palette: 1: White, 2: Green, 3: Yellow, 4: Red (Center)
local COLORS = { ESC .. "[37m", ESC .. "[32m", ESC .. "[33m", ESC .. "[31m" }

function p:init()
    math.randomseed(os.time())
end

function p:render(bands, frame, rows, cols)
    if cols < 20 or rows < 5 then return "Expand Window" end

    local mid_y = math.floor(rows / 2)
    local mid_x = math.floor(cols / 2)
    
    local grid = {}
    for r = 1, rows do
        grid[r] = {}
        for c = 1, cols do grid[r][c] = SPACE_CHAR end
    end

    -- Use bass intensity to determine expansion width
    local bass = math.min(1.0, (bands[1] or 0))
    local expansion = math.floor(bass * (cols / 2))

    for c = 1, cols, 2 do 
        local dist_from_mid = math.abs(c - mid_x)
        
        if dist_from_mid <= expansion then
            -- Map column position to frequency band
            local band_idx = math.floor((dist_from_mid / (cols / 2)) * #bands) + 1
            local val = math.min(1.0, bands[band_idx] or 0)
            local bar_height = math.floor(val * (rows / 2) * 0.9)
            
            -- Gradient logic: Center (Red) to Outer edges (White)
            local grad_idx = 4
            if expansion > 0 then
                local ratio = dist_from_mid / expansion
                grad_idx = #COLORS - math.floor(ratio * (#COLORS - 1))
            end
            local color = COLORS[math.max(1, math.min(#COLORS, grad_idx))]
            
            for h = 0, bar_height do
                -- Toggle between block and dot for visual needle effect
                local char = (h % 3 == 0) and "█" or "·"
                
                -- Render bars symmetrically above and below center line
                if mid_y + h < rows and mid_y + h >= 1 then grid[mid_y + h][c] = color .. char .. RESET end
                if mid_y - h > 0 and mid_y - h <= rows then grid[mid_y - h][c] = color .. char .. RESET end
            end
        end
    end

    local output_lines = {}
    for r = 1, rows do
        output_lines[r] = table.concat(grid[r])
    end
    return table.concat(output_lines, "\n")
end
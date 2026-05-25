-- A dynamic, center-expanding spectrum visualizer for cliamp,
-- featuring discrete bars with an intensity-based color gradient

local p = plugin.register({ name = "nightrider", type = "visualizer" })

local ESC = string.char(27)
local RESET = ESC .. "[0m"
local SPACE_CHAR = " "
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

    local bass = math.min(1.0, (bands[1] or 0))
    local expansion = math.floor(bass * (cols / 2))

    for c = 1, cols, 2 do 
        local dist_from_mid = math.abs(c - mid_x)
        
        if dist_from_mid <= expansion then
            local band_idx = math.floor((dist_from_mid / (cols / 2)) * #bands) + 1
            local val = math.min(1.0, bands[band_idx] or 0)
            local bar_height = math.floor(val * (rows / 2) * 0.9)
            
            -- Map intensity to base color index
            local base_color_idx = math.min(#COLORS, math.floor(val * (#COLORS - 1)) + 1)
            
            for h = 0, bar_height do
                -- Calculate color gradient relative to current bar height
                local relative_pos = (bar_height > 0) and (h / bar_height) or 0
                local grad_idx = math.min(#COLORS, base_color_idx + math.floor(relative_pos * 2))
                local color = COLORS[grad_idx]
                
                -- Create discrete needle look
                local char = (h % 3 == 0) and "█" or "·"
                
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
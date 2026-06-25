-- A dynamic, center-expanding spectrum visualizer for cliamp,
-- featuring discrete bars with an intensity-based color gradient.
-- When nothing is playing it falls into an idle "waiting" sweep.

local p = plugin.register({ name = "Nightrider", type = "visualizer" })

local ESC = string.char(27)
local RESET = ESC .. "[0m"
local SPACE_CHAR = " "
-- K.I.T.T. Palette: 1: White, 2: Green, 3: Yellow, 4: Red (hot)
local COLORS = { ESC .. "[37m", ESC .. "[32m", ESC .. "[33m", ESC .. "[31m" }

-- Idle ("waiting") animation tuning -------------------------------------------
local SILENCE_THRESH = 0.02   -- max band level below which a frame counts as silent
local WIDTH_PEAK     = 1.00   -- width gating: 1.0 = bass & treble open it equally (loudest band), 0.0 = needs broad energy
local IDLE_AFTER     = 20     -- silent frames before the idle sweep starts
local IDLE_SWEEP_SECS = 1.20  -- real seconds for one left->right pass (time-paced, FPS-independent; lower = faster)
local IDLE_REACH     = 0.40   -- width of the moving glow, as a fraction of the bar
local IDLE_BASE      = 0.25   -- idle bar base height (fraction of half-height)
local IDLE_BUMP      = 0.55   -- extra height at the sweep position
-- -----------------------------------------------------------------------------

-- Draw one vertical bar of `height`, symmetric around the centre line, in `color`.
local function draw_column(grid, mid_y, rows, c, height, color)
    for h = 0, height do
        local char = (h % 3 == 0) and "█" or "·"   -- block/dot needle texture
        if mid_y + h <= rows then grid[mid_y + h][c] = color .. char .. RESET end
        if mid_y - h >= 1    then grid[mid_y - h][c] = color .. char .. RESET end
    end
end

function p:init()
    math.randomseed(os.time())
    self.silent_frames = 0
    self.sweep_phase = 0
    self.last_clock = os.clock()
end

function p:render(bands, frame, rows, cols)
    if cols < 20 or rows < 5 then return "Expand Window" end
    bands = bands or {}
    self.silent_frames = self.silent_frames or 0

    -- Scan the spectrum once: peak (silence detection) + mean (overall energy).
    local peak, sum = 0, 0
    for i = 1, #bands do
        local v = bands[i] or 0
        if v > peak then peak = v end
        sum = sum + v
    end
    local mean = (#bands > 0) and (sum / #bands) or 0

    if peak < SILENCE_THRESH then
        self.silent_frames = self.silent_frames + 1
    else
        self.silent_frames = 0
    end
    local idle = self.silent_frames >= IDLE_AFTER

    -- Real-time delta for FPS-independent sweep pacing; clamp so a stall/pause can't leap it.
    local now = os.clock()
    local dt = now - (self.last_clock or now)
    self.last_clock = now
    if dt < 0 then dt = 0 elseif dt > 0.3 then dt = 0.3 end

    local mid_y = math.floor((rows + 1) / 2)   -- true vertical centre
    local mid_x = math.floor(cols / 2)

    local grid = {}
    for r = 1, rows do
        grid[r] = {}
        for c = 1, cols do grid[r][c] = SPACE_CHAR end
    end

    if idle then
        -- IDLE: full-width band with a bright glow sweeping left <-> right.
        -- Time-paced (not frame-paced) so cliamp's idle FPS throttling can't slow it down.
        self.sweep_phase = ((self.sweep_phase or 0) + dt / IDLE_SWEEP_SECS) % 2.0
        local t = self.sweep_phase
        local tri = (t < 1.0) and t or (2.0 - t)         -- 0..1..0 ping-pong
        local sweep_x = 1 + tri * (cols - 1)
        local reach = math.max(1, cols * IDLE_REACH)

        for c = 1, cols do
            if math.abs(c - mid_x) % 2 == 0 then         -- every 2nd column, centre-anchored
                local prox = math.max(0, 1 - math.abs(c - sweep_x) / reach)
                local grad_idx = math.max(1, math.min(#COLORS, 1 + math.floor(prox * (#COLORS - 1) + 0.5)))
                local color = COLORS[grad_idx]
                local height = math.floor((rows / 2) * (IDLE_BASE + IDLE_BUMP * prox))
                draw_column(grid, mid_y, rows, c, height, color)
            end
        end
    else
        -- ACTIVE: audio-reactive center-expanding spectrum (the voice box).
        -- Whole-spectrum energy drives the width (peak-weighted so any strong band
        -- -- bass, mids OR vocals -- opens it; bar heights stay per-frequency-band).
        local energy = math.min(1.0, WIDTH_PEAK * peak + (1.0 - WIDTH_PEAK) * mean)
        local expansion = math.floor(energy * (cols / 2))

        for c = 1, cols do
            local dist_from_mid = math.abs(c - mid_x)
            -- every 2nd column, anchored on the centre so the spine stays solid
            if dist_from_mid % 2 == 0 and dist_from_mid <= expansion then
                -- map column to a frequency band (clamped to the band count)
                local band_idx = math.min(#bands, math.floor((dist_from_mid / (cols / 2)) * #bands) + 1)
                local val = math.min(1.0, bands[band_idx] or 0)
                local height = math.floor(val * (rows / 2) * 0.9)

                -- gradient: centre (Red) to outer edges (White)
                local grad_idx = 4
                if expansion > 0 then
                    local ratio = dist_from_mid / expansion
                    grad_idx = #COLORS - math.floor(ratio * (#COLORS - 1))
                end
                local color = COLORS[math.max(1, math.min(#COLORS, grad_idx))]

                draw_column(grid, mid_y, rows, c, height, color)
            end
        end
    end

    local output_lines = {}
    for r = 1, rows do
        output_lines[r] = table.concat(grid[r])
    end
    return table.concat(output_lines, "\n")
end

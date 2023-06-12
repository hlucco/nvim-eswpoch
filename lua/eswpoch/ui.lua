local util = require("eswpoch.util")
local timezones = require("eswpoch.timezones")
local api = vim.api
local buf, win_height, win_width, win

local function open_window()
    buf = api.nvim_create_buf(false, true)
    local border_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    win_height = math.ceil(height * 0.2 - 5)
    win_width = math.ceil(width * 0.3)

    local opts = {
        style = "minimal",
        relative = "cursor",
        width = win_width,
        height = win_height,
        row = 1,
        col = 0
    }

    win = api.nvim_open_win(buf, true, opts)
    -- print(c_row, c_col)
    api.nvim_command('au BufWipeout <buffer> exe " silent bwipeout! "'..border_buf)

    api.nvim_win_set_option(win, 'cursorline', true)

    api.nvim_buf_set_lines(buf, 0, -1, false, {
        util.center('Eswpoch'), '', ''
    })
    api.nvim_buf_add_highlight(buf, -1, 'EswpochHeader', 0, 0, -1)
    api.nvim_win_set_cursor(win, {2, 0})

    return buf
end

local function gen_divider()
    local result = ""
    for i=1, win_width do
        result = result.."="
    end
    return result
end

local function close_window()
    api.nvim_win_close(win, true)
end

local function move_cursor(down)
    local new_pos = math.max(2, api.nvim_win_get_cursor(win)[1] - 1)

    if down then
        new_pos = math.min(6 + util.get_len(timezones), api.nvim_win_get_cursor(win)[1] + 1)
    end

    if new_pos == 6 and down then
        new_pos = 7
    elseif new_pos == 6 then
        new_pos = 5
    end
    api.nvim_win_set_cursor(win, {new_pos, 0})
end

return {
    gen_divider = gen_divider,
    close_window = close_window,
    open_window = open_window,
    move_cursor = move_cursor,
}

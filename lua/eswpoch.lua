local api = vim.api
local buf, win
local c_row, c_col
local line
local parent_buf
local win_width
local win_height

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

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
        center('Eswpoch'), '', ''
    })
    api.nvim_buf_add_highlight(buf, -1, 'EswpochHeader', 0, 0, -1)
    api.nvim_win_set_cursor(win, {2, 0})
end

local function trim(s)
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

local function get_token()
    local char_idx = 1
    local token_idx = 1
    local result = ""
    local trim_line = trim(line)
    for token in string.gmatch(trim_line, "%S+") do
        local trim_token = trim(token)
        -- print(token)
        char_idx = char_idx + string.len(trim_token)
        -- print(char_idx, token_idx, char_idx + token_idx, c_col)
        if char_idx + token_idx + 1>= c_col then
            result = token
            break
        end
        token_idx = token_idx + 1
    end
    return result
end

local function gen_divider(l)
    local result = ""
    for i=1, l do
        result = result.."="
    end
    return result
end

local function render_options(token)
    api.nvim_buf_set_option(buf, 'modifiable', true)
    local digits = string.len(token)
    local unit = 's';

    if digits >= 12 then
        unit = 'ms'
    end

    if digits >= 15 then
        unit = 'us'
    end

    if digits >= 17 then
        unit = 'ns'
    end

    local conversions = {
        s = {
            s = 1,
            ms = 1000,
            us = 1e6,
            ns = 1e9
        },
        ms = {
            s = 1/1000,
            ms = 1,
            us = 1000,
            ns = 1e6
        },
        us = {
            s = 1/1e6,
            ms = 1/1000,
            us = 1,
            ns = 1000
        },
        ns = {
            s = 1/1e9,
            ms = 1/1e6,
            us = 1/1000,
            ns = 1
        }
    }

    local conversion_results = {}
    local initial_value = tonumber(token)
    local conversion_table = conversions[unit]
    for unit, mult in pairs(conversion_table) do
        local c = initial_value * mult
        conversion_results[unit] = c
    end

    local i = 1
    local unit_s = 0

    for unit, c in pairs(conversion_results) do
        if unit == 's' then
            unit_s = c
        end
        local formatted_entry = string.format("%.f", c)
        local line_entry = unit..": "..formatted_entry
        api.nvim_buf_set_lines(buf, i, i + 1, false, {line_entry})
        i = i + 1
    end

    api.nvim_buf_set_lines(buf, i, i+1, false, {gen_divider(win_width)})
    i = i + 1

    local timezones = {
        America_Los_Angeles = -7,
        America_Chicago = -5,
        America_New_York = -4,
        Pacific_Honolulu = -10
    }

    for k,v in pairs(timezones) do
        local date_string = os.date("!%a %b %d, %I:%M %p, %Y", unit_s + (v * 60 * 60))
        local line_entry = k..": "..date_string
        api.nvim_buf_set_lines(buf, i, i+1, false, {line_entry})
        i = i + 1
    end


    api.nvim_buf_set_option(buf, 'modifiable', false)

end

local function close_window()
    api.nvim_win_close(win, true)
end

local function move_cursor(down)
    local new_pos = math.max(2, api.nvim_win_get_cursor(win)[1] - 1)

    if down then
        new_pos = math.min(num_options, api.nvim_win_get_cursor(win)[1] + 1)
    end

    if new_pos == 6 and down then
        new_pos = 7
    elseif new_pos == 6 then
        new_pos = 5
    end
    api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function split(s, delim)
    local result = {}
    local count = 1
    for i in string.gmatch(s, delim) do
        result[count] = i
        count = count + 1
    end
    return result
end

local function insert_selection()
    local token = get_token()
    local anchor = string.find(line, token)
    local active = anchor + string.len(token)

    local insert_value = trim(split(api.nvim_get_current_line(), "([^:]+)")[2])
    local split_point = string.find(api.nvim_get_current_line(), ":")
    local insert_tokens = split(api.nvim_get_current_line(), "([^:]+)")

    local count = 1
    for k, v in pairs(insert_tokens) do
        count = count + 1
    end

    if (count > 3) then
        insert_value = '"'..trim(string.sub(api.nvim_get_current_line(), split_point+1))..'"'
    end

    local new_line = string.sub(line, 1, anchor-1)..insert_value..string.sub(line, active, string.len(line))
    local ts = 1658669410000000000
    api.nvim_buf_set_lines(parent_buf, c_row-1, c_row, false, {new_line})
    close_window()
end

local function set_mappings()
    local mappings = {
        q = 'close_window()',
        k = 'move_cursor(false)',
        j = 'move_cursor(true)',
        ['<cr>'] = 'insert_selection()'
    }

    for k, v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"eswpoch".'..v..'<cr>',{
            nowait = true, noremap = true, silent = true
        })
    end

    local other_chars = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', ':', 'h', 'l'
    }

    for k,v in ipairs(other_chars) do
        api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
    end
end

local function eswpoch()
    parent_buf = api.nvim_win_get_buf(0)
    c_row, c_col = unpack(api.nvim_win_get_cursor(0))
    line = api.nvim_buf_get_lines(0, c_row-1, c_row, false)[1]
    local token = get_token()
    open_window()
    render_options(token)
    set_mappings()
end

return {
    eswpoch = eswpoch,
    close_window = close_window,
    move_cursor = move_cursor,
    insert_selection = insert_selection
}

local util = require("eswpoch.util")
local ui = require("eswpoch.ui")
local timezones = require("eswpoch.timezones")

local api = vim.api
local c_row, c_col
local line
local parent_buf

local function get_token()
    local char_idx = 1
    local token_idx = 1
    local result = ""
    local trim_line = util.trim(line)
    for token in string.gmatch(trim_line, "%S+") do
        local trim_token = util.trim(token)
        char_idx = char_idx + string.len(trim_token)
        if char_idx + token_idx + 1>= c_col then
            result = token
            break
        end
        token_idx = token_idx + 1
    end
    return result
end

local function render_options(token, buf)
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

    api.nvim_buf_set_lines(buf, i, i+1, false, {ui.gen_divider()})
    i = i + 1

    for k,v in pairs(timezones) do
        local date_string = os.date("!%a %b %d, %I:%M %p, %Y", unit_s + (v * 60 * 60))
        local line_entry = k..": "..date_string
        api.nvim_buf_set_lines(buf, i, i+1, false, {line_entry})
        i = i + 1
    end

    api.nvim_buf_set_option(buf, 'modifiable', false)

end

local function insert_selection()
    local token = get_token()
    local anchor = string.find(line, token)
    local active = anchor + string.len(token)

    local insert_value = util.trim(util.split(api.nvim_get_current_line(), "([^:]+)")[2])
    local split_point = string.find(api.nvim_get_current_line(), ":")
    local insert_tokens = util.split(api.nvim_get_current_line(), "([^:]+)")

    local count = 1
    for k, v in pairs(insert_tokens) do
        count = count + 1
    end

    if (count > 3) then
        insert_value = '"'..util.trim(string.sub(api.nvim_get_current_line(), split_point+1))..'"'
    end

    local new_line = string.sub(line, 1, anchor-1)..insert_value..string.sub(line, active, string.len(line))
    local ts = 1658669410000000000
    api.nvim_buf_set_lines(parent_buf, c_row-1, c_row, false, {new_line})
    ui.close_window()
end

local function set_mappings(buf)
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
    local buf = ui.open_window()
    render_options(token, buf)
    set_mappings(buf)
end

return {
    eswpoch = eswpoch,
    close_window = ui.close_window,
    move_cursor = ui.move_cursor,
    insert_selection = insert_selection
}

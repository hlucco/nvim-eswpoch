local api = vim.api

local function get_len(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end

    return count
end

local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function trim(s)
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
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

return {
    get_len = get_len,
    center = center,
    trim = trim,
    split = split
}

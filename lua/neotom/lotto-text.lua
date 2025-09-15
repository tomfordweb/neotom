local M = {}

M.setup = function(options)
  M.options = options or {
    direction = "horizontal",
    fonts = {}
  }
end

local function mergeTables(destinationTable, sourceTable)
  for i = 1, #sourceTable do
    table.insert(destinationTable, sourceTable[i])
  end
  return destinationTable
end

local function multi_line_text_to_table(result)
  local pos, fonttbl = 0, {}
  for st, sp in function() return string.find(result, "\n", pos, true) end do
    table.insert(fonttbl, string.sub(result, pos, st - 1))
    pos = sp + 1
  end
  table.insert(fonttbl, string.sub(result, pos))
  return fonttbl
end

local function make_sentence(lines)
  local list = {}
  for i, val in ipairs(lines) do
    table.insert(list, val[math.random(#val)])
  end
  return list
end

M.getText = function(lines, fonts)
  local output = {}
  local font = fonts[math.random(#fonts)];
  local sentence = make_sentence(lines)

  if (M.options['direction'] == "horizontal") then
    local result = vim.fn.system('figlet  --width 999 -f ' .. font .. ' "' .. table.concat(sentence, " ") .. '"')
    output = multi_line_text_to_table(result)
  else
    for i, val in ipairs(lines) do
      local result = vim.fn.system('figlet -f ' .. font .. ' ' .. val[math.random(#val)])
      mergeTables(output, multi_line_text_to_table(result))
    end
  end
  return output
end;

M.merge_tables = mergeTables

return M

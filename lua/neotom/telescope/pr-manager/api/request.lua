local M = {}

local plenary = require('plenary')

M.factory = function(args)
  return {
    command = 'curl',
    args = vim.iter({ args, '--header', string.format('PRIVATE-TOKEN: %s', M.config.GITLAB_PAT), '--request', 'GET' })
        :flatten():totable()
  }
end


M._list_result_telescope_formatter = function(json)
  local results = {}

  for i, value in ipairs(vim.json.decode(job[1])) do
    table.insert(results, vim.json.encode(value))
  end

  return results
end

M.get = function(opts)
  local request =  M.factory(opts)
  local response = plenary.job:new(request):sync()
  return M._list_result_telescope_formatter(response)
end


return M

local conf = require('telescope.config').values
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')
local plenary = require('plenary')

local log = require('plenary.log').new {
  plugin = 'neotom_gitlab',
  level = 'info',
}

local M = {}

local make_curl_command = function(args)
  local job_opts = {
    command = 'curl',
    args = vim.iter({ args, '--header', string.format('PRIVATE-TOKEN: %s', M.config.GITLAB_PAT), '--request', 'GET' })
        :flatten():totable()
  }

  -- log.info('Running job', job_opts)
  local job = plenary.job:new(job_opts):sync()
  -- log.info('Ran job', vim.inspect(job))


  local results = {}

  for i, value in ipairs(vim.json.decode(job[1])) do
    table.insert(results, vim.json.encode(value))
  end

  return results
end

local cache = {
  merge_requests = nil,
};

local gitlab_merge_requests = function(opts)
  pickers
      .new(opts, {
        finder = finders.new_dynamic({
          fn = function()
            if cache['merge_requests'] == nil then
              cache.merge_requests = make_curl_command({
                '--url',
                string.format('%s/api/v4/merge_requests?state=opened&scope=all', M.config.GITLAB_URL),
              })
              log.info('Fetched merge requests from GitLab API')
            else
              log.info('Using cached merge requests')
            end

            return cache.merge_requests;
          end,

          entry_maker = function(entry)
            local merge_request = vim.json.decode(entry)
            if merge_request then
              return {
                value = merge_request,
                display = string.format("󰮠 %s - %s", merge_request.title, merge_request.author.username),
                ordinal = merge_request.source_branch ..
                    ' ' ..
                    merge_request.title .. ' ' .. merge_request.author.username .. ' ' .. merge_request.author.name,
              }
            end
          end,
        }),
        sorter = conf.generic_sorter(opts),

        previewer = previewers.new_buffer_previewer({
          title = 'Volume Details',
          define_preview = function(self, entry)
            local formatted = {
              '# ' .. entry.display,
              '',
              '*Title*: ' .. entry.value.title,
              '*URL*: ' .. entry.value.web_url,
              '*Namespace*: ' .. entry.value.references.full,
            }
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)

            utils.highlighter(self.state.bufnr, 'markdown')
          end,
        }),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            vim.cmd("!open " .. action_state.get_selected_entry().value.web_url)
            -- clear the cache on close
            cache.merge_requests = nil
          end)
          return true
        end,
      })
      :find()
end

M.setup = function(config)
  M.config = config;
end

M.merge_requests = gitlab_merge_requests

return M

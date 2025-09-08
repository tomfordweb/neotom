require('neotom')
require('mhvdc')

local formattedDate = os.date("%H:%M:%S")

local handle = io.popen("git log --pretty=format:'%h' -n 1")
local commit_hash = handle:read("*a")
handle:close()

-- Remove any trailing newline or whitespace characters
commit_hash = commit_hash:gsub("%s+$", "")

print("neotom:", commit_hash, "loaded at", formattedDate)

-- Kudos: https://github.com/hlissner/.hammerspoon/blob/master/util.lua
return {
  apps = {},
  bindings = {},

  ls = function(directory)
    local i, t, popen = 0, {}, io.popen
    for filename in popen('ls -a "'..directory..'"'):lines() do
      i = i + 1
      t[i] = filename
    end
    return t
  end,

  reload = function()
    hs.reload()
    hs.alert("Config reloaded!")
  end,

  call = function(obj, fn)
    return function () return obj[fn](obj) end
  end,

  autoimport = function(dir)
    for _, file in pairs(util.ls(dir)) do
      -- Anchored so only files *ending* in .lua load; append anything
      -- (e.g. ".disable") to the filename to skip a module.
      local name = file:match("^([^.].-)%.lua$")
      if name then
        print(name .. " loaded")
        require(dir .. "/" .. name)
      end
    end
  end
}

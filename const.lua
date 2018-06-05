return function (x)
	  return setmetatable({}, { __index = x,
				    __newindex = function(table, key, value)
						    error("Attempt to modify read-only table")
						 end,
				    __metatable = false
				 })
end

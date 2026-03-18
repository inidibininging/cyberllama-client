local Districts = {
    data = {}
}

function Districts.Init(tryDecodeJson)
  Districts.data = {}
  local f = assert(io.open("./districts/districts.json"))
	local lines = ''
  lines = f:read("*a")
  print(lines)
	local tableDis = {}
	tableDis = tryDecodeJson(lines, f, "./districts/districts.json")
  Districts.data = tableDis
end

return Districts

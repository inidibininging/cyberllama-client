
-- local TryDecodeJson =
-- borrowed from cyberscript
-- pls dont kill me
function TryDecodeJson(text, file, path)
  local jsonArr = nil
  if not pcall(function ()
    if(path == nil) then
      path = "Unknown"
    end
    jsonArr = json.decode(text)
    return jsonArr
  end) then
    print('could not load ' .. file)
  end
  if not jsonArr then
    jsonArr = {}
  end
  return jsonArr
end
return TryDecodeJson


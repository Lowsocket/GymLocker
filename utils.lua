Draw3DText = function(x, y, z, text)
   local onScreen, _x, _y = World3dToScreen2d(x,y,z)
   local px, py, pz = table.unpack(GetGameplayCamCoords())
   local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

   local scale = (1 / dist) * 1
   local fov = (1 / GetGameplayCamFov()) * 100
   local scale = 2.5

   if onScreen then
      SetTextScale(0.0 * scale, 0.18 * scale)
      SetTextFont()
      SetTextProportional(1)
      SetTextDropShadow(0, 0, 0, 0, 255)
      SetTextEdge(2, 0, 0, 0, 150)
      SetTextEntry("STRING")
      SetTextCentre(1)
      AddTextComponentString(text)
      DrawText(_x, _y)

      local factor = (string.len(text)) / 350
      DrawRect(_x, _y + 0.0115, 0.01 + factor, 0, 0, 0, 0, 255)

   end
end

Marker = function(hint, x, y, z)
   Draw3DText(x, y, z + 0.0, hint)
   DrawMarker(21, x, y, z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 230, 255, 100, false, true, 2, true, false, false, false)
end
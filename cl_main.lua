ESX = nil
local CurrentActionData = {}
local consuming = false

Citizen.CreateThread(function()
      while ESX == nil do
         Citizen.Wait(50)
         ESX = exports["es_extended"]:getSharedObject()
      end
end)


-- Here you can change the blip --
Citizen.CreateThread(function()

   --for place, value in pairs(Config.Zones) do
   --   local blip = AddBlipForCoord(value["coords"].x, value["coords"].y)
   --   SetBlipSprite(blip, 238)
   --   SetBlipDisplay(blip, 4)
   --   SetBlipScale(blip, 0.5)
   --   SetBlipColour(blip, 69)
   --   SetBlipAsShortRange(blip, true)
   --   BeginTextCommandSetBlipName("STRING")
   --   AddTextComponentString(place)
   --   EndTextCommandSetBlipName(blip)
   --end

   while true do
      local sleepTime = 500
      local coords = GetEntityCoords(PlayerPedId())

      for place, value in pairs(Config.Zones) do
         local dst = GetDistanceBetweenCoords(coords, value["coords"], true)
         local text = place

         if dst <= 7.5 then
            sleepTime = 5

            if dst <= 1.25 then
               text = "Klik op ~o~[E]~w~ voor " .. place
               if IsControlJustReleased(0, 38) then
                  GymKluisje(place)
               end
            end

            Marker(text, value["coords"].x, value["coords"].y, value["coords"].z - 0.00)
         end
      end

      Citizen.Wait(sleepTime)
   end
end)

GymKluisje = function(place)
   ESX.UI.Menu.Open('default', GetCurrentResourceName(), "ClothesStashCollection",
   {
      title = place,
      align = "top-right",
      elements = {
         { ["label"] = "KlerenKast", ["type"] = "clothes" },
         { ["label"] = "Kleding verwijderen", ["type"] = "remove_cloth" },
         { ["label"] = "Spullen Wegleggen", ["type"] = "player_inventory" },
         { ["label"] = "Spullen Pakken", ["type"] = "room_inventory" }
      }

   }, function(data, menu)

         local type = data.current.type

         if type == 'clothes' then
            
            ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
               local elements = {}

               for i = 1, #dressing, 1 do
                  table.insert(elements, {
                     label = dressing[i],
                     value = i
                  })
               end

               ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_dressing', {
                  title = "Mijn Kleren",
                  align = "top-right",
                  elements = elements
               }, function(data2, menu2)

                  TriggerEvent('skinchanger:getSkin', function(skin)
                     ESX.TriggerServerCallback('esx_property:getPlayerOutfit', function(clothes)
                        TriggerEvent('skinchanger:loadClothes', skin, clothes)
                        TriggerEvent('esx_skin:setLastSkin', skin)

                        TriggerEvent('skinchanger:getSkin', function(skin)
                           TriggerServerEvent('esx_skin:save', skin)
                        end)
                     end, data2.current.value)
                  end)
               end, function(data2, menu2)
                  menu2.close()
               end)
            end)

         elseif type == 'remove_cloth' then
            
            ESX.TriggerServerCallback('esx_property:getPlayerDressing', function(dressing)
               local elements = {}

               for i = 1, #dressing, 1 do
                  table.insert(elements, {
                     label = dressing[i],
                     value = i
                  })
               end

               ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'remove_cloth', {
                  title = "Verwijder Kleren",
                  align = "top-right",
                  elements = elements
               }, function(data2, menu2)
                  menu2.close()
                  TriggerServerEvent('esx_property:removeOutfit', data2.current.value)
                  ESX.ShowNotification('De outfit is uit je Klerenkast gehaald!.')
               end, function(data2, menu2)
                  menu2.close()
               end)
            end)

         elseif type == 'player_inventory' then
            
            OpenPlayerInventoryMenu(CurrentActionData, ESX.GetPlayerData().identifier)

         elseif type == 'room_inventory' then
            
            OpenRoomInventoryMenu(CurrentActionData, ESX.GetPlayerData().identifier)

         end
   
   end, function(data, menu)
      menu.close()
   end)
end

function OpenPlayerInventoryMenu(property, owner)

   ESX.TriggerServerCallback('esx_property:getPlayerInventory', function(inventory)
      local elements = {}

      if inventory.blackMoney > 0 then
         table.insert(elements, {
            label = 'ZwartGeld: <span style = "color: red;">'.. ESX.Math.GroupDigits(inventory.blackMoney) ..'</span>',
            type  = 'item_account',
            value = 'black_money'
         })
      end

      for i = 1, #inventory.items, 1 do
         local item = inventory.items[i]

         if item.count > 0 then
            table.insert(elements, {
               label = item.label .. ' x' .. item.count,
               type  = 'item_standard',
               value = item.name
            })
         end
      end

      for i = 1, #inventory.weapons, 1 do
         local weapon = inventory.weapons[i]

         table.insert(elements, {
            label = weapon.label .. ' [' .. weapon.ammo .. ']',
            type  = 'item_weapon',
            value = weapon.name,
            ammo  = weapon.ammo
         })
      end

      ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_inventory', {
         title = "Inventory",
         align = "top-right",
         elements = elements
      }, function(data, menu)

         if data.current.type == 'item_weapon' then
            menu.close()
            TriggerServerEvent('esx_property:putItem', owner, data.current.type, data.current.value, data.current.ammo)

            ESX.SetTimeout(300, function()
               OpenPlayerInventoryMenu(property, owner)
            end)
         else
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
               title = 'Amount?'
            }, function(data2, menu2)
               local quantity = tonumber(data2.value)

               if quantity == nil then
                  ESX.ShowNotification('Ongeldige hoeveelheid')
               else
                  menu2.close()
                  TriggerServerEvent('esx_property:putItem', owner, data.current.type, data.current.value, tonumber(data2.value))
                  ESX.SetTimeout(300, function()
                     OpenPlayerInventoryMenu(property, owner)
                  end)
               end
            end, function(data2, menu2)
               menu2.close()
            end)
         end
      end, function(data, menu)
         menu.close()
      end)
   end)

end

                     
function OpenRoomInventoryMenu(property, owner)

   ESX.TriggerServerCallback('esx_property:getPropertyInventory', function(inventory)
      local elements = {}

      if inventory.blackMoney > 0 then
         table.insert(elements, {
            label = 'ZwartGeld: <span style = "color: red;">'.. ESX.Math.GroupDigits(inventory.blackMoney) ..'</span>',
            type  = 'item_account',
            value = 'black_money'
         })
      end

      for i = 1, #inventory.items, 1 do
         local item = inventory.items[i]

         if item.count > 0 then
            table.insert(elements, {
               label = item.label .. ' x' .. item.count,
               type  = 'item_standard',
               value = item.name
            })
         end
      end

      for i = 1, #inventory.weapons, 1 do
         local weapon = inventory.weapons[i]

         table.insert(elements, {
            label = ESX.GetWeaponLabel(weapon.name) .. ' [' .. weapon.ammo .. ']',
            type  = 'item_weapon',
            value = weapon.name,
            ammo  = weapon.ammo
         })
      end

      ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'room_inventory', {
         title = "Inventory",
         align = "top-right",
         elements = elements
      }, function(data, menu)

         if data.current.type == 'item_weapon' then
            menu.close()
            TriggerServerEvent('esx_property:getItem', owner, data.current.type, data.current.value, data.current.ammo)
            ESX.SetTimeout(300, function()
               OpenRoomInventoryMenu(property, owner)
            end)
         else
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'get_item_count', {
               title = 'Amount?'
            }, function(data2, menu)
               local quantity = tonumber(data2.value)

               if quantity == nil then
                  ESX.ShowNotification('Ongeldige Hoeveelheid')
               else
                  menu.close()
                  TriggerServerEvent('esx_property:getItem', owner, data.current.type, data.current.value, quantity)
                  ESX.SetTimeout(300, function()
                     OpenRoomInventoryMenu(property, owner)
                  end)
               end
            end, function(data2, menu)
               menu.close()
            end)
         end
      end, function(data, menu)
         menu.close()
      end)
   end, owner)

end
function makePed() 

    ped1 = createPed(73, 2446.6708984375, -1138.775390625, 34.614665985107) 
    setTimer(function() 
        setPedRotation(ped1, 89.29) 
        setPedAnimation(ped1, "ped", "floor_hit") 
     end, 100, 1) 

    ped2 = createPed(274, 2446.6240234375, -1137.740234375, 34.620719909668) 
    setTimer(function() 
        setPedRotation(ped2, 176.86) 
        setPedAnimation(ped2, "medic", "cpr") 
     end, 100, 1) 

    ped3 = createPed(277, 1792.369140625, -1444.734375, 13.546875) 
    setTimer(function() 
        setPedRotation(ped3, 68.17) 
        setPedAnimation(ped3, "ped", "idle_chat") 
     end, 100, 1) 

    ped4 = createPed(279, 1790.099609375, -1444.21484375, 13.546875) 
    setTimer(function() 
        setPedRotation(ped4, 251.17) 
        setPedAnimation(ped4, "ped", "idle_chat") 
     end, 100, 1) 

end 
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), makePed)
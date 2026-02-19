function makePed() 

    ped1 = createPed(27,  -2029.54296875, -346.474609375, 35.418441772461) 
    setTimer(function() 
        setPedRotation(ped1, 313.31) 
        setPedAnimation(ped1, "crack", "crckdeth2") 
     end, 100, 1) 

    ped2 = createPed(56, -2049.2587890625, -343.1435546875, 35.3046875) 
    setTimer(function() 
        setPedRotation(ped2, 91.90) 
        setPedAnimation(ped2, "ped", "floor_hit") 
     end, 100, 1) 

    ped3 = createPed(274, -2049.1000976563, -344, 35.299999237061) 
    setTimer(function() 
        setPedRotation(ped3, 11.10) 
        setPedAnimation(ped3, "medic", "cpr") 
     end, 100, 1) 

    ped4 = createPed(219, -2052.3999023438, -343.29998779297, 35.299999237061) 
    setTimer(function() 
        setPedRotation(ped4, 356.40) 
        setPedAnimation(ped4, "crack", "crckdeth2") 
     end, 100, 1) 

    ped5 = createPed(281, -2141.57421875, -334.494140625, 35.09358215332) 
    setTimer(function() 
        setPedRotation(ped5, 176.75) 
        setPedAnimation(ped5, "ped", "idle_chat") 
     end, 100, 1) 

    ped6 = createPed(283, -2141.5185546875, -336.90234375, 35.093227386475) 
    setTimer(function() 
        setPedRotation(ped6, 358.9) 
        setPedAnimation(ped6, "ped", "idle_chat") 
     end, 100, 1) 

    ped7 = createPed(276, -2052.3000488281, -344.60000610352, 35.299999237061) 
    setTimer(function() 
        setPedRotation(ped7, 4.31) 
        setPedAnimation(ped7, "ped", "idle_tired") 
     end, 100, 1) 

end 
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), makePed)
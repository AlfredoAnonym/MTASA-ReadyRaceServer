function makePed() 

    ped1 = createPed(282,  2538.6999511719, 1964.5, 10.800000190735) 
    setTimer(function() 
        setPedRotation(ped1, 94) 
        setPedAnimation(ped1, "ped", "idle_armed") 
	givePedWeapon(ped1, 31, 1, true)
     end, 100, 1) 

    ped2 = createPed(28, 2536.8000488281, 1962.6999511719, 10.800000190735) 
    setTimer(function() 
        setPedRotation(ped2, 88.75) 
        setPedAnimation(ped2, "ped", "cower") 
     end, 100, 1) 

    ped3 = createPed(281, 2541.8999023438, 1962.5, 10.800000190735) 
    setTimer(function() 
        setPedRotation(ped3, 1) 
        setPedAnimation(ped3, "ped", "gang_gunstand") 
	givePedWeapon(ped3, 24, 1, true)
     end, 100, 1) 

    ped4 = createPed(285, 2548.1000976563, 1962.4000244141, 10.800000190735) 
    setTimer(function() 
        setPedRotation(ped4, 1) 
        setPedAnimation(ped4, "ped", "gang_gunstand")
	givePedWeapon(ped4, 24, 1, true) 
     end, 100, 1) 

    ped5 = createPed(143, 2541.8000488281, 1965.0999755859, 10.800000190735) 
    setTimer(function() 
        setPedRotation(ped5, 180.75) 
        setPedAnimation(ped5, "ghands", "gsign1") 
     end, 100, 1) 

    ped6 = createPed(29, 2548.1000976563, 1965.3000488281, 10.800000190735) 
    setTimer(function() 
        setPedRotation(ped6, 179.5) 
        setPedAnimation(ped6, "ghands", "gsign1") 
     end, 100, 1) 

end 
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), makePed)
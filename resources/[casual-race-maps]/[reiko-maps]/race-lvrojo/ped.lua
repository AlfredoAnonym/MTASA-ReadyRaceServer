function makePed() 

    ped1 = createPed(7, 2481.2600097656, 1845.7396240234, 15.26406288147) 
    setTimer(function() 
        setPedRotation(ped1, 260.5) 
        setPedAnimation(ped1, "riot", "riot_punches") 
     end, 100, 1) 

    ped2 = createPed(14, 2490.8791503906, 1840.4873046875, 12.22500038147) 
    setTimer(function() 
        setPedRotation(ped2, 261.76) 
        setPedAnimation(ped2, "riot", "riot_shout") 
     end, 100, 1) 

    ped3 = createPed(15, 2487.0100097656, 1836.04296875, 13.537485122681) 
    setTimer(function() 
        setPedRotation(ped3, 270) 
        setPedAnimation(ped3, "strip", "pun_holler") 
     end, 100, 1) 

    ped4 = createPed(16, 2482.5617675781, 1832.384765625, 14.83437538147) 
    setTimer(function() 
        setPedRotation(ped4, 270) 
        setPedAnimation(ped4, "strip", "pun_cash") 
     end, 100, 1) 

    ped5 = createPed(20, 2486.9953613281, 1829.845703125, 13.537485122681) 
    setTimer(function() 
        setPedRotation(ped5, 270) 
        setPedAnimation(ped5, "strip", "ply_cash") 
     end, 100, 1) 

    ped6 = createPed(22, 2491.3078613281, 1824.5888671875, 12.232479095459) 
    setTimer(function() 
        setPedRotation(ped6, 270) 
        setPedAnimation(ped6, "strip", "pun_holler") 
     end, 100, 1) 

    ped7 = createPed(27, 2485.6389160156, 1818.87890625, 13.95937538147) 
    setTimer(function() 
        setPedRotation(ped7, 270) 
        setPedAnimation(ped7, "ghands", "gsign2lh") 
     end, 100, 1) 

    ped8 = createPed(35, 2491.1259765625, 1812.4384765625, 12.22500038147) 
    setTimer(function() 
        setPedRotation(ped8, 270) 
        setPedAnimation(ped8, "riot", "riot_punches") 
     end, 100, 1) 

    ped9 = createPed(167, 2487.0205078125, 1806.919921875, 13.537485122681) 
    setTimer(function() 
        setPedRotation(ped9, 275) 
        setPedAnimation(ped9, "bsktball", "bball_def_jump_shot") 
     end, 100, 1) 

    ped10 = createPed(177, 2482.9453125, 1801.109375, 14.83437538147) 
    setTimer(function() 
        setPedRotation(ped10, 287) 
        setPedAnimation(ped10, "riot", "riot_angry") 
     end, 100, 1) 

    ped11 = createPed(189, 2488.927734375, 1799.822265625, 13.09218788147) 
    setTimer(function() 
        setPedRotation(ped11, 295) 
        setPedAnimation(ped11, "riot", "riot_shout") 
     end, 100, 1) 

    ped12 = createPed(184, 2481.5849609375, 1797.2421875, 15.25665473938) 
    setTimer(function() 
        setPedRotation(ped12, 290) 
        setPedAnimation(ped12, "rapping", "laugh_01") 
     end, 100, 1) 


end 
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), makePed)
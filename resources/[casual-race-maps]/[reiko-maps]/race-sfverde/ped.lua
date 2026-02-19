function makePed() 

    ped1 = createPed(7, -1932.1083984375, 79.0625, 30.02968788147) 
    setTimer(function() 
        setPedRotation(ped1, 8.44) 
        setPedAnimation(ped1, "riot", "riot_punches") 
     end, 100, 1) 

    ped2 = createPed(14, -1934.837890625, 74.853515625, 31.33437538147) 
    setTimer(function() 
        setPedRotation(ped2, 4.61) 
        setPedAnimation(ped2, "riot", "riot_shout") 
     end, 100, 1) 

    ped3 = createPed(15, -1940.095703125, 76.1845703125, 30.889255523682) 
    setTimer(function() 
        setPedRotation(ped3, 1.43) 
        setPedAnimation(ped3, "strip", "pun_holler") 
     end, 100, 1) 

    ped4 = createPed(16, -1945.5595703125, 78.935546875, 30.037485122681) 
    setTimer(function() 
        setPedRotation(ped4, 2.38) 
        setPedAnimation(ped4, "strip", "pun_cash") 
     end, 100, 1) 

    ped5 = createPed(20, -1950.7001953125, 76.1337890625, 30.889255523682) 
    setTimer(function() 
        setPedRotation(ped5, 356.7) 
        setPedAnimation(ped5, "strip", "ply_cash") 
     end, 100, 1) 

    ped6 = createPed(22, -1955.0029296875, 80.484375, 29.59218788147) 
    setTimer(function() 
        setPedRotation(ped6, 354.47) 
        setPedAnimation(ped6, "strip", "pun_holler") 
     end, 100, 1) 

    ped7 = createPed(27, -1956.8466796875, 76.29296875, 30.889255523682) 
    setTimer(function() 
        setPedRotation(ped7, 351.54) 
        setPedAnimation(ped7, "ghands", "gsign2lh") 
     end, 100, 1) 

    ped8 = createPed(35, -1963.0126953125, 74.9658203125, 31.33437538147) 
    setTimer(function() 
        setPedRotation(ped8, 347) 
        setPedAnimation(ped8, "riot", "riot_punches") 
     end, 100, 1) 

    ped9 = createPed(167, -1969.2294921875, 74.6826171875, 31.33437538147) 
    setTimer(function() 
        setPedRotation(ped9, 356) 
        setPedAnimation(ped9, "bsktball", "bball_def_jump_shot") 
     end, 100, 1) 

    ped10 = createPed(177, -1976.296875, 78.9541015625, 30.037485122681) 
    setTimer(function() 
        setPedRotation(ped10, 337.94) 
        setPedAnimation(ped10, "riot", "riot_angry") 
     end, 100, 1) 

    ped11 = createPed(189, -1986.109375, 75.017578125, 31.33437538147) 
    setTimer(function() 
        setPedRotation(ped11, 334.75) 
        setPedAnimation(ped11, "riot", "riot_shout") 
     end, 100, 1) 

    ped12 = createPed(184, -1994.283203125, 76.4482421875, 30.89687538147) 
    setTimer(function() 
        setPedRotation(ped12, 342) 
        setPedAnimation(ped12, "rapping", "laugh_01") 
     end, 100, 1) 


end 
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), makePed)
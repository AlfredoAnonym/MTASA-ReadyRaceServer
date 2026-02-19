function makePed() 

    ped1 = createPed(7, 2191.7468261719, -2015.5166015625, 14.78750038147) 
    setTimer(function() 
        setPedRotation(ped1, 197.90) 
        setPedAnimation(ped1, "riot", "riot_punches") 
     end, 100, 1) 

    ped2 = createPed(14, 2186.2907714844, -2008.220703125, 15.232479095459) 
    setTimer(function() 
        setPedRotation(ped2, 191) 
        setPedAnimation(ped2, "riot", "riot_shout") 
     end, 100, 1) 

    ped3 = createPed(15, 2182.4128417969, -2007.8740234375, 14.357265472412) 
    setTimer(function() 
        setPedRotation(ped3, 186.3) 
        setPedAnimation(ped3, "strip", "pun_holler") 
     end, 100, 1) 

    ped4 = createPed(16, 2187.6276855469, -2001.7216796875, 16.95937538147) 
    setTimer(function() 
        setPedRotation(ped4, 174.40) 
        setPedAnimation(ped4, "strip", "pun_cash") 
     end, 100, 1) 

    ped5 = createPed(20, 2175.7844238281, -1995.8685302734, 15.662271499634) 
    setTimer(function() 
        setPedRotation(ped5, 171.6) 
        setPedAnimation(ped5, "strip", "ply_cash") 
     end, 100, 1) 

    ped6 = createPed(22, 2164.1984863281, -1988.0404052734, 14.78750038147) 
    setTimer(function() 
        setPedRotation(ped6, 191.62) 
        setPedAnimation(ped6, "strip", "pun_holler") 
     end, 100, 1) 

    ped7 = createPed(27, 2174.4777832031, -1986.3089599609, 17.389255523682) 
    setTimer(function() 
        setPedRotation(ped7, 179.07) 
        setPedAnimation(ped7, "ghands", "gsign2lh") 
     end, 100, 1) 

    ped8 = createPed(35, 2160.4943847656, -1976.1136474609, 16.52968788147) 
    setTimer(function() 
        setPedRotation(ped8, 199.74) 
        setPedAnimation(ped8, "riot", "riot_punches") 
     end, 100, 1) 

    ped9 = createPed(167, 2185.0202636719, -2012.6298828125, 13.92031288147) 
    setTimer(function() 
        setPedRotation(ped9, 188.52) 
        setPedAnimation(ped9, "bsktball", "bball_def_jump_shot") 
     end, 100, 1) 

    ped10 = createPed(177, 2166.4055175781, -1994.2181396484, 13.92031288147) 
    setTimer(function() 
        setPedRotation(ped10, 193.22) 
        setPedAnimation(ped10, "riot", "riot_angry") 
     end, 100, 1) 

    ped11 = createPed(189, 2193.9929199219, -2011.9462890625, 16.09218788147) 
    setTimer(function() 
        setPedRotation(ped11, 169.09) 
        setPedAnimation(ped11, "riot", "riot_shout") 
     end, 100, 1) 

    ped12 = createPed(184, 2171.2990722656, -1989.3245849609, 16.09218788147) 
    setTimer(function() 
        setPedRotation(ped12, 196.04) 
        setPedAnimation(ped12, "rapping", "laugh_01") 
     end, 100, 1) 


end 
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), makePed)
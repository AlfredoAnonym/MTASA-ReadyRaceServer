function replaceTXD() 

txd1 = engineLoadTXD ( "textures/vgebillboards.txd" )
engineImportTXD ( txd1, 7906 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


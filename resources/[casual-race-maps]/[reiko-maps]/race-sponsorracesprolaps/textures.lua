function replaceTXD() 

txd1 = engineLoadTXD ( "textures/vgebillboards.txd" )
engineImportTXD ( txd1, 7910 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


function replaceTXD() 

txd1 = engineLoadTXD ( "textures/vgebillboards.txd" )
engineImportTXD ( txd1, 7913 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


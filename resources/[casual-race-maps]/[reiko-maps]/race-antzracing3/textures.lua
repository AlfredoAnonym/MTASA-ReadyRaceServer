function replaceTXD() 

txd = engineLoadTXD ( "textures/vgsegarage.txd" )
engineImportTXD ( txd, 8957 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


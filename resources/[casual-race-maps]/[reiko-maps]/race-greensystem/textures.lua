function replaceTXD() 

txd = engineLoadTXD ( "textures/metalbarrier.txd" )
engineImportTXD ( txd, 978 )
engineImportTXD ( txd, 979 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


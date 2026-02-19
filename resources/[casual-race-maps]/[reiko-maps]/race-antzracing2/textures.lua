function replaceTXD() 

txd1 = engineLoadTXD ( "textures/vgnbasktball.txd" )
engineImportTXD ( txd1, 6959 )

txd2 = engineLoadTXD ( "textures/vgsegarage.txd" )
engineImportTXD ( txd2, 8957 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


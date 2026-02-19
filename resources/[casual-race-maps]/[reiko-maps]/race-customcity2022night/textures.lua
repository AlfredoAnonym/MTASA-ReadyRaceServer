function replaceTXD() 

txd1 = engineLoadTXD ( "textures/a51jdrx.txd" )
engineImportTXD ( txd1, 3095 )

txd2 = engineLoadTXD ( "textures/pirateland.txd" )
engineImportTXD ( txd2, 8832 )

txd3 = engineLoadTXD ( "textures/vgwestland.txd" )
engineImportTXD ( txd3, 7474 )

txd4 = engineLoadTXD ( "textures/cs_mountaintop.txd" )
engineImportTXD ( txd4, 18368 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


function replaceTXD() 

txd1 = engineLoadTXD ( "textures/a51jdrx.txd" )
engineImportTXD ( txd1, 3095 )

txd2 = engineLoadTXD ( "textures/haight1_sfs.txd" )
engineImportTXD ( txd2, 10722 )

txd3 = engineLoadTXD ( "textures/vgnbasktball.txd" )
engineImportTXD ( txd3, 6959 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


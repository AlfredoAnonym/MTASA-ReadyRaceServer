function replaceTXD() 

txd1 = engineLoadTXD ( "textures/sjmla_las.txd" )
engineImportTXD ( txd1, 3578 )

txd2 = engineLoadTXD ( "textures/vgnbasktball.txd" )
engineImportTXD ( txd2, 6959 )

txd3 = engineLoadTXD ( "textures/vgsegarage.txd" )
engineImportTXD ( txd3, 8957 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


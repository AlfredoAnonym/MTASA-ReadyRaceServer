function replaceTXD() 

txd1 = engineLoadTXD ( "textures/sjmla_las.txd" )
engineImportTXD ( txd1, 3578 )
		
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


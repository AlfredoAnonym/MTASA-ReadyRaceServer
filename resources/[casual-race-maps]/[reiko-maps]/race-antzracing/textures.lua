function replaceTXD() 

txd1 = engineLoadTXD ( "textures/vgnbasktball.txd" )
engineImportTXD ( txd1, 6959 )

end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceTXD)


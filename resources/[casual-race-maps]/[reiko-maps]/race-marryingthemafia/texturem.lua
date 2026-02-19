function BillboardClient ()
txd = engineLoadTXD("vgnusedcar.txd") 
engineImportTXD(txd, 7910 )
end
addEventHandler( "onClientResourceStart", resourceRoot, BillboardClient )
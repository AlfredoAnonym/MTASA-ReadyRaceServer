function MetalBarrierClient ()
txd = engineLoadTXD("metalbarrier.txd") 
engineImportTXD(txd, 978 )
engineImportTXD(txd, 979 )
end
addEventHandler( "onClientResourceStart", resourceRoot, MetalBarrierClient )
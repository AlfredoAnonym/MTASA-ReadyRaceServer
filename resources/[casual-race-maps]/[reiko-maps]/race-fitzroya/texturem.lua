function GrassClient ()
txd = engineLoadTXD("compomark_lae2.txd") 
engineImportTXD(txd, 17864 )
end
addEventHandler( "onClientResourceStart", resourceRoot, GrassClient )
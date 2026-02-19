addEventHandler('onClientResourceStart', resourceRoot,
function()

txd = engineLoadTXD ( "vgebillboards.txd" )
engineImportTXD ( txd, 7910 )

txd2 = engineLoadTXD ( "vgsegarage.txd" )
engineImportTXD ( txd2, 8957 )

end
)

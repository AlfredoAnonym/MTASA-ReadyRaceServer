addEventHandler('onClientResourceStart', resourceRoot,
function()

txd = engineLoadTXD ( "vgebillboards.txd" )
engineImportTXD ( txd, 7913 )
engineImportTXD ( txd, 7915 )

txd2 = engineLoadTXD ( "vgsegarage.txd" )
engineImportTXD ( txd2, 8957 )

end
)

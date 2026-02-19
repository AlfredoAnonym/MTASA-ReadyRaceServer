addEventHandler('onClientResourceStart', resourceRoot,
function()

txd = engineLoadTXD ( "vgebillboards.txd" )
engineImportTXD ( txd, 7906 )
engineImportTXD ( txd, 7912 )

txd2 = engineLoadTXD ( "vgsegarage.txd" )
engineImportTXD ( txd2, 8957 )

end
)

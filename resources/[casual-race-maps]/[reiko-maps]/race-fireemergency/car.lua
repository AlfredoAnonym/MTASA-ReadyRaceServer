function replaceModel() 
  txd = engineLoadTXD("fbiranch.txd", 490 )
  engineImportTXD(txd, 490)
  dff = engineLoadDFF("fbiranch.dff", 490 )
  engineReplaceModel(dff, 490)
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceModel)
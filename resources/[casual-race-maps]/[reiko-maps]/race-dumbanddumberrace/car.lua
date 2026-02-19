function replaceModel() 
  txd = engineLoadTXD("sandking.txd", 495 )
  engineImportTXD(txd, 495)
  dff = engineLoadDFF("sandking.dff", 495 )
  engineReplaceModel(dff, 495)
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), replaceModel)
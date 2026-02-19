addEventHandler("onClientResourceStart",getRootElement(),
	function()
		if not fileExists("settings.xml") then
			local settings = xmlCreateFile("settings.xml","AutoLogin")
			local Username = xmlCreateChild(settings,"Username")
			local Password = xmlCreateChild(settings,"Password")
			local Serial = xmlCreateChild(settings,"Serial")
			xmlSaveFile(settings)
		end
		local node = xmlLoadFile ("settings.xml")
		local Username = xmlFindChild(node,"Username",0)
		local Password = xmlFindChild(node,"Password",0)
		local Serial = xmlFindChild(node,"Serial",0)
		local pass = xmlNodeGetValue(Password)
		local user = xmlNodeGetValue(Username)
		local serial = xmlNodeGetValue(Serial)
		if getPlayerSerial(localPlayer) == serial then
			triggerServerEvent("triggerThis",getLocalPlayer(),user,pass)
		end
	end
	)

addCommandHandler("autologin",
	function(command,username,password)
		local node = xmlLoadFile ("settings.xml")
		local Username = xmlFindChild(node,"Username",0)
		local Password = xmlFindChild(node,"Password",0)
		local Serial = xmlFindChild(node,"Serial",0)
		local user = xmlNodeGetValue(Username)
		local pass = xmlNodeGetValue(Password)
		local serial = xmlNodeGetValue(Serial)
		if user == "none" or user == "" then
			xmlNodeSetValue(Username,username)
			xmlNodeSetValue(Password,password)
			xmlNodeSetValue(Serial,getPlayerSerial(getLocalPlayer()))
			xmlSaveFile(node)
		else
			xmlNodeSetValue(Username,"none")
			xmlNodeSetValue(Password,"none")
			xmlNodeSetValue(Serial,"none")
			xmlSaveFile(node)
		end
end )
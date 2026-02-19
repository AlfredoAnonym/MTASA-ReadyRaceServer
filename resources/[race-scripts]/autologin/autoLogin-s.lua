addEvent("triggerThis",true)
addEventHandler("triggerThis",getRootElement(),
function(user,pass)
	logIn(source,getAccount(user),pass)
	outputChatBox("You have been automatically logged in to #FFFFFF"..user.."'s#00FF00 account!",source,0,255,0,true)
	outputChatBox("To disable AutoLogin, use /autologin!",source,0,255,0,true)
end )
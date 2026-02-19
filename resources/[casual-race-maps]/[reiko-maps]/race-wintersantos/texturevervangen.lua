local shader
signTep = { }
signFirstTick = getTickCount ( )
signId1 = 1


addEventHandler( "onClientResourceStart", resourceRoot,
	function()
		shader, tec = dxCreateShader ( "texreplace.fx" )
		if not shader then
			outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			engineApplyShaderToWorldTexture ( shader, "heat_02" )
			if not loadPrutTextures ( ) then
				outputChatBox ( "Loading sign textures failed")
				destroyElement ( shader )
				return
			end
			dxSetShaderValue ( shader, "gTexture", signTep[1] )
			addEventHandler ( "onClientHUDRender", getRootElement (), renderAap )
		end
	end
)



function loadPrutTextures ( )
	for i = 0, 3 do
		local tex = dxCreateTexture ( "stopbord/left/lframe"..i..".png" )
		if not tex then
			unloadPrutTextures ( )
			return false
		end
		table.insert ( signTep, tex )
	end
	
	return true
end

function unloadPrutTextures ( )
	for index, tex in ipairs ( signTep ) do
		destroyElement ( tex )
	end
end

function renderAap ( )
	if getTickCount ( ) - signFirstTick < 200 then
		return
	end
	signId1 = signId1 + 1
	if signId1 > #signTep then
		signId1 = signId1 - #signTep
	end
	dxSetShaderValue ( shader, "gTexture", signTep [ signId1 ] )
	signFirstTick = getTickCount ( )
end




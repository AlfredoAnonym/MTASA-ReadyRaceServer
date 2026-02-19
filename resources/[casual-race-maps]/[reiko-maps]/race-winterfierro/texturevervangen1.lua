local shader
signTex = { }
signLastTick = getTickCount ( )
signId = 1


addEventHandler( "onClientResourceStart", resourceRoot,
	function()
		shader, tec = dxCreateShader ( "texreplace.fx" )
		if not shader then
			outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			engineApplyShaderToWorldTexture ( shader, "prolaps02" )
			if not loadsignTextures ( ) then
				outputChatBox ( "Loading sign textures failed")
				destroyElement ( shader )
				return
			end
			dxSetShaderValue ( shader, "gTexture", signTex[1] )
			addEventHandler ( "onClientHUDRender", getRootElement (), renderScreen )
		end
	end
)



function loadsignTextures ( )
	-- Gotta load 'em all!
	for i = 0, 3 do
		local tex = dxCreateTexture ( "stopbord/right/rframe"..i..".png" )
		if not tex then
			unloadsignTextures ( )
			return false
		end
		table.insert ( signTex, tex )
	end
	
	return true
end

function unloadsignTextures ( )
	for index, tex in ipairs ( signTex ) do
		destroyElement ( tex )
	end
end

function renderScreen ( )
	if getTickCount ( ) - signLastTick < 200 then
		return
	end
	signId = signId + 1
	if signId > #signTex then
		signId = signId - #signTex
	end
	dxSetShaderValue ( shader, "gTexture", signTex [ signId ] )
	signLastTick = getTickCount ( )
end




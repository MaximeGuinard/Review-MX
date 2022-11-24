--[[  
	Addon : Anais Review
	By : Anais
]]

Anais.Review.Ragdolls = Anais.Review.Ragdolls or {}
Anais.Review.Vehs = Anais.Review.Vehs or {}

net.Receive( "Anais:Review:Player:OpenMenu", function()
	local tblList = net.ReadTable()
	local pSelected = Entity( 0 )

	local Base = vgui.Create( "DFrame" )
	Base:SetSize( 700, 450 )
	Base:Center()
	Base:SetTitle( '' )
	Base:MakePopup()
	function Base:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, Color( 200, 10, 10, 100 ) )
        draw.RoundedBox( 0, w / 4, 10, w / 2, 40, Color( 36, 36, 36 ) )

		draw.SimpleText( "Revu des scènes", "Trebuchet24", w / 2, 10 + 40 / 2, color_white, 1, 1 )
	end

	local pList = vgui.Create( "DScrollPanel", Base )
	pList:SetSize( 400, Base:GetTall() - 95 - 15 )
	pList:SetPos( Base:GetWide() / 2 - ( pList:GetWide() / 2 ), 95 )

    local pPlayer = vgui.Create( "DComboBox", Base )
    pPlayer:SetSize( 400, 25 )
    pPlayer:SetPos( Base:GetWide() / 2 - ( pPlayer:GetWide() / 2 ), 60 )
    pPlayer:SetValue( "Choissisez un joueur..." )
    for k,v in pairs( player.GetAll() ) do
    	pPlayer:AddChoice( v:Nick() .. ' ( ' .. v:getDarkRPVar('job') .. " )", v )
    end
	pPlayer.OnSelect = function( index, value, data )
		pSelected = pPlayer:GetOptionData( value )

		pList:Clear()

		for k,v in pairs( tblList[ pSelected:SteamID() ] or {} ) do
			local panel = vgui.Create( "DPanel", pList )
			panel:SetSize( pList:GetWide(), 30 )
			panel:Dock( TOP )
			panel:DockMargin( 0, 5, 0, 0 )
			function panel:Paint( w, h )
				draw.RoundedBox( 0, 0, 0, w, h, Color( 36, 36, 36 ) )

				local TimeString = os.date( "%H:%M:%S" , v['Date'] )

				if v['Infos'] && v['Infos']['Attacker'] && v['Infos']['Attacker']['Name'] then
					draw.SimpleText( v['Infos']['Attacker']['Name'], "Trebuchet18", 5, h / 2, color_white, 0, 1 )
				end

				draw.SimpleText( TimeString, "Trebuchet18", w - 5, h / 2, color_white, 2, 1 )
			end

			local btn = vgui.Create( "DButton", panel )
			btn:SetSize( panel:GetWide(), panel:GetTall() )
			btn:SetText( '' )
			btn.Paint = nil
			function btn:DoClick()
				net.Start( "Anais:Review:Player:View" )
				net.WriteString( pSelected:SteamID() )
				net.WriteInt( k, 32 )
				net.SendToServer()

				Base:Remove()
			end
		end
	end
end)

function Anais.Review:RemoveElements()
    for k,v in pairs( Anais.Review.Ragdolls or {} ) do
        if IsValid( v ) then
            v:Remove()
        end

        Anais.Review.Ragdolls[k] = nil
    end

    for k,v in pairs( Anais.Review.Vehs or {} ) do
        if IsValid( v ) then
            v:Remove()
        end

        Anais.Review.Vehs[k] = nil
    end
end

function Anais.Review:CreateP( tblInfos )
	if !tblInfos then return end

	local entRagdoll = ClientsideRagdoll( tblInfos['Model'], RENDERGROUP_OPAQUE )

	if !IsValid( entRagdoll ) then return end

	do
		for i = 0, entRagdoll:GetPhysicsObjectCount() - 1 do
			local intBone = entRagdoll:GetPhysicsObjectNum( i )

			if !IsValid( intBone ) then continue end
			if !tblInfos[ 'Bones' ][i] then continue end

			posBone, angBone = tblInfos['Bones'][i][1], tblInfos['Bones'][i][2]

			if !posBone then continue end
			if !angBone then continue end

			intBone:SetPos( posBone )
			intBone:SetAngles( angBone )
			intBone:EnableMotion( false )
		end

		entRagdoll:SetNoDraw( false )
		entRagdoll:DrawShadow( true )
	end

	if tblInfos['Vehicle'] && tblInfos['Vehicle']['Model'] && tblInfos['Vehicle']['Pos'] && tblInfos['Vehicle']['Ang'] then
		local entVeh = ClientsideModel( tblInfos['Vehicle']['Model'], RENDERGROUP_OPAQUE )
		entVeh:SetPos( tblInfos['Vehicle']['Pos'] )
		entVeh:SetAngles( tblInfos['Vehicle']['Ang'] )
		entVeh:SetSkin( tblInfos['Vehicle']['Skin'] or 0 )
		entVeh:SetColor( tblInfos['Vehicle']['Color'] )

		table.insert( Anais.Review.Vehs or {}, entVeh )
	end

	table.insert( Anais.Review.Ragdolls or {}, entRagdoll )

	return entRagdoll
end

net.Receive( "Anais:Review:Player:View", function()
	local tblInfos = net.ReadTable()
	local Cur = CurTime()

	local tblVictim = tblInfos['Infos']['Victim']
	local tblAttacker = tblInfos['Infos']['Attacker']

	if !tblVictim then return end
	if !tblAttacker then return end

	Anais.Review:RemoveElements()

	local entVictim = Anais.Review:CreateP( tblVictim )
	local entAttacker = Anais.Review:CreateP( tblAttacker )

	hook.Add( "HUDPaint", "Anais:Review:".. Cur, function()
		if !IsValid( entVictim ) then
			hook.Remove( "HUDPaint", "Anais:Review:".. Cur )
		else
			local pos = entVictim:GetPos()

			pos.z = pos.z + 40
			pos = pos:ToScreen()

			draw.SimpleText( "Victime", "Trebuchet18", pos.x + 1, pos.y - 120, color_white, 1 )
			draw.SimpleText( "Nom RP : " .. tblVictim['Name'], "Trebuchet18", pos.x + 1, pos.y - 90, color_white, 1 )
			draw.SimpleText( "SteamID : " .. tblVictim['SteamID'], "Trebuchet18", pos.x + 1, pos.y - 70, color_white, 1 )
			draw.SimpleText( "Job : " .. tblVictim['Job'], "Trebuchet18", pos.x + 1, pos.y - 50, color_white, 1 )
			draw.SimpleText( "Argent : " .. DarkRP.formatMoney( tblVictim['Money'] ), "Trebuchet18", pos.x + 1, pos.y - 30, color_white, 1 )
			draw.SimpleText( "Arme : " .. tblVictim['Weapon'], "Trebuchet18", pos.x + 1, pos.y - 10, color_white, 1 )
		end

		if !IsValid( entAttacker ) then
			hook.Remove( "HUDPaint", "Anais:Review:".. Cur )
		else
			local pos = entAttacker:GetPos()

			pos.z = pos.z + 40
			pos = pos:ToScreen()

			draw.SimpleText( "Victime", "Trebuchet18", pos.x + 1, pos.y - 120, color_white, 1 )
			draw.SimpleText( "Nom RP : " .. tblAttacker['Name'], "Trebuchet18", pos.x + 1, pos.y - 90, color_white, 1 )
			draw.SimpleText( "SteamID : " .. tblAttacker['SteamID'], "Trebuchet18", pos.x + 1, pos.y - 70, color_white, 1 )
			draw.SimpleText( "Job : " .. tblAttacker['Job'], "Trebuchet18", pos.x + 1, pos.y - 50, color_white, 1 )
			draw.SimpleText( "Argent : " .. DarkRP.formatMoney( tblAttacker['Money'] ), "Trebuchet18", pos.x + 1, pos.y - 30, color_white, 1 )
			draw.SimpleText( "Arme : " .. tblAttacker['Weapon'], "Trebuchet18", pos.x + 1, pos.y - 10, color_white, 1 )
		end
	end)
end)

local intBtnCoolDown = 0
hook.Add( "PlayerButtonDown", "Anais:Review:Player:BtnDown", function( pPlayer, intBtn )
	if intBtn == Anais.Review.KeyToReturn then
		if !intBtnCoolDown || CurTime() > intBtnCoolDown then
			Anais.Review:RemoveElements()

			net.Start( "Anais:Review:Player:Return" )
			net.SendToServer()

			intBtnCoolDown = CurTime() + 0.5
		end
	end
end)
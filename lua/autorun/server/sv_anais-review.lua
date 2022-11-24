--[[  
	Addon : Anais Review
	By : Anais
]]

Anais.Review.List = Anais.Review.List or {}

-- Initialize networks
util.AddNetworkString( "Anais:Review:Player:OpenMenu" )
util.AddNetworkString( "Anais:Review:Player:View" )
util.AddNetworkString( "AnaisAnais:Review:Player:Return" )

-- Player Say
hook.Add( "PlayerSay", "Anais:Review:Player:Say", function( pPlayer, strText )
	if strText == Anais.Review.Command then
		if Anais.Review.Groups[ pPlayer:GetUserGroup() ] then
			net.Start( "Anais:Review:Player:OpenMenu" )
			net.WriteTable( Anais.Review.List or {} )
			net.Send( pPlayer )
		end

		return ""
	end
end)

-- Player Death
hook.Add( "PlayerDeath", "Anais:Review:Player:Death", function( pVictim, _, pAttacker )
	if !IsValid( pAttacker ) then return end
	if pVictim == pAttacker then return end

	local intTime = 2

	if !Anais.Review.List then Anais.Review.List = {} end

	if pAttacker:IsVehicle() then
		pAttacker = pAttacker:GetDriver()
	end

	if !IsValid( pAttacker ) then return end
	if !pAttacker:IsPlayer() then return end

	if !pAttacker.Anais_Review_I[ #pAttacker.Anais_Review_I - intTime ] then
		return
	end

	local tblAttackerI = pAttacker.Anais_Review_I[ #pAttacker.Anais_Review_I - intTime ]
	local tblVictimI = pVictim.Anais_Review_I[ #pVictim.Anais_Review_I - intTime ]

	if !tblAttackerI then return end
	if !tblVictimI then return end

	local tblAttacker = {
		Name = pAttacker:Nick(),
		SteamID = pAttacker:SteamID(),
		Health = tblAttackerI['Health'],
		Model = tblAttackerI['Model'],
		Job = pAttacker:getDarkRPVar( 'job' ),
		Money = pAttacker:getDarkRPVar( 'money' ),
		Weapon = tblAttackerI['Weapon'],
		Vehicle = tblAttackerI['Vehicle'],

		Pos = tblAttackerI['Pos'],
		Ang = tblAttackerI['Ang'],
		Bones = tblAttackerI['Bones'],
	}

	local tblVictim = {
		Name = pVictim:Nick(),
		SteamID = pVictim:SteamID(),
		Health = tblVictimI['Health'],
		Model = tblVictimI['Model'],
		Job = pVictim:getDarkRPVar( 'job' ),
		Money = pVictim:getDarkRPVar( 'money' ),
		Weapon = tblVictimI['Weapon'],
		Vehicle = tblVictimI['Vehicle'],

		Pos = tblVictimI['Pos'],
		Ang = tblVictimI['Ang'],
		Bones = tblVictimI['Bones'],
	}

	if !Anais.Review.List[ pVictim:SteamID() ] then Anais.Review.List[ pVictim:SteamID() ] = {} end

	table.insert( Anais.Review.List[ pVictim:SteamID() ], {
		Date = os.time(),
		Infos = {
			['Victim'] = tblVictim,
			['Attacker'] = tblAttacker,
		}
	} )
end)

-- Timers
timer.Destroy( "Anais:Review:Save" )

timer.Create( "Anais:Review:Reset", Anais.Review.DelayToReset, 0, function()
	for k,v in pairs( player.GetAll() ) do
		if v.Anais_Review_I then v.Anais_Review_I = nil end
	end
end)

timer.Create( "Anais:Review:Save", 0.1, 0, function()
	for k,v in pairs( player.GetAll() ) do
		if !v.Anais_Review_I then v.Anais_Review_I = {} end

		if !v:Alive() then continue end

		local Bones = {}

		for i = 0, v:GetBoneCount() - 1 do
			local intBone = i

			if intBone then
				posBone, angBone = v:GetBonePosition( v:TranslatePhysBoneToBone( intBone ) )

				Bones[ intBone ] = { posBone, angBone }
			end
		end

		local strWep = v:GetActiveWeapon()

		if IsValid( strWep ) then
			strWep = strWep:GetClass()
		else
			strWep = "Aucun"
		end

		local tblVeh = {}
		local entVeh = v:GetVehicle()

		if IsValid( entVeh ) then
			tblVeh = {
				Model = entVeh:GetModel(),
				Pos = entVeh:GetPos(),
				Ang = entVeh:GetAngles(),
				Skin = entVeh:GetSkin(),
				Color = entVeh:GetColor()
			}
		end

		table.insert( v.Anais_Review_I or {}, {
			Pos = v:GetPos(),
			Ang = v:GetAngles(),
			Model = v:GetModel(),
			Bones = Bones,
			Weapon = strWep,
			Vehicle = tblVeh,
		} )
	end
end)

-- Player View Request
net.Receive( "Anais:Review:Player:View", function( _, pPlayer )
	local strSteamID = net.ReadString()
	local intKey = net.ReadInt( 32 )

	if !Anais.Review.List[ strSteamID ] then return end
	if !Anais.Review.List[ strSteamID ][ intKey ] then return end

	if !Anais.Review.List[ strSteamID ][ intKey ]['Infos'] && !Anais.Review.List[ strSteamID ][ intKey ]['Infos']['Victim'] || !Anais.Review.List[ strSteamID ][ intKey ]['Infos']['Victim']['Pos'] then
		return
	end

	pPlayer.Anais_Review_Return = pPlayer:GetPos()

	pPlayer:SetPos( Anais.Review.List[ strSteamID ][ intKey ]['Infos']['Victim']['Pos'] )

	net.Start( "Anais:Review:Player:View" )
	net.WriteTable( Anais.Review.List[ strSteamID ][ intKey ] or {} )
	net.Send( pPlayer )
end)

-- Player return
net.Receive( "Anais:Review:Player:Return", function( _, pPlayer )
	if !Anais.Review.Groups[ pPlayer:GetUserGroup() ] then return end

	if pPlayer.Anais_Review_Return then
		pPlayer:SetPos( pPlayer.Anais_Review_Return )
	end

	pPlayer.Anais_Review_Return = nil
end)
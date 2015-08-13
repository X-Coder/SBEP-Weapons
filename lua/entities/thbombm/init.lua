
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

util.PrecacheSound( "Buttons.snd26" )

function ENT:Initialize()

	self.Entity:SetModel( "models/props_phx/torpedo.mdl" )
	self.Entity:SetName("Torpedo")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	--self.Entity:SetMaterial("models/props_combine/combinethumper002")
	self.Inputs = Wire_CreateInputs( self.Entity, { "Drop" } )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:EnableCollisions(true)
	end

    --self.Entity:SetKeyValue("rendercolor", "0 0 0")
	self.PhysObj = self.Entity:GetPhysicsObject()
	self.CAng = self.Entity:GetAngles()
	
	self.CBCount = 0
	self.LBomb = nil
	self.Ready = true
	self.MCDown = 0
	self.BTime = 0
end

function ENT:TriggerInput(iname, value)		
	
	if (iname == "Drop") then
		if (value > 0) then
			self.Entity:HPFire()
		end
	end
	
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,50)
	
	local ent = ents.Create( "THBombM" )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	return ent
	
end

function ENT:Think()
	if !self.Ready then
		if CurTime() > self.MCDown then
			self.Ready = true
			self.Entity:EmitSound("Buttons.snd26")
			self.Entity:SetColor(Color(255,255,255,255))
		end
	end
	if self.CBCount > 0 and CurTime() > self.BTime then
		self.Entity:BombDrop()
		self.CBCount = self.CBCount - 1
		self.BTime = CurTime() + 0.5
	end
	
	self.Entity:NextThink( CurTime() + 0.1 )
	return true
end

function ENT:PhysicsCollide( data, physobj )

end

function ENT:OnTakeDamage( dmginfo )

end

function ENT:Use( activator, caller )

end

function ENT:Touch( ent )
	if ent.HasHardpoints then
		if ent.Cont and ent.Cont:IsValid() then HPLink( ent.Cont, ent.Entity, self.Entity ) end
	end
end

function ENT:HPFire()
	if CurTime() > self.MCDown then
		self.CBCount = 1
		self.MCDown = CurTime() + 10
		self.Entity:SetColor(Color(0,0,0,1))
	end
end

function ENT:BombDrop()
	local NewShell = ents.Create( "THBomb" )
	if ( !NewShell:IsValid() ) then return end
	NewShell:SetPos( self.Entity:GetPos() + (self.Entity:GetUp() * -60 ) )
	NewShell:SetAngles( self.Entity:GetAngles() )
	NewShell.SPL = self.SPL
	NewShell:Spawn()
	NewShell.Armed = true
	NewShell:Initialize()
	NewShell:Activate()
	local NC = constraint.NoCollide(self.Entity, NewShell, 0, 0)
	if self.LBomb and self.LBomb:IsValid() then
		NC = constraint.NoCollide(self.LBomb, NewShell, 0, 0)
	end
	NewShell:GetPhysicsObject():SetVelocity((self.Entity:GetPhysicsObject():GetVelocity() * 0.5))
	NewShell:Fire("kill", "", 10)
	NewShell:GetPhysicsObject():EnableCollisions(false)
	timer.Simple(1,function()
		if NewShell:IsValid() then
		NewShell:GetPhysicsObject():EnableCollisions(true)
		end
	 end)
	self.Ready = false
end
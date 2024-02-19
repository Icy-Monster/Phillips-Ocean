--!strict
--!native
--!optimize 2

-- @IcyMonstrosity, 2023
-- Original C++ implementation: https://github.com/Scrawk/Phillips-Ocean



---------------------------------------
---------------CONSTANTS---------------

--// The gravity being used
local GRAVITY: number = 9.81

--// The Philips Spectrum parameter. Affects water height.
--// Setting this too high can cause the waves to curl back
--// on themselves.
local WAVE_AMPLITUDE = 0.0004

--// The size of the furier, must be a pow2 number. It is a sort of resolution of the Ocean
local FURIER_SIZE: number = 64

--// The ocean mesh length size
local MESH_LENGTH: number = 64

--// The Speed of the Wind in the relevant axis
local WIND_SPEED: Vector2 = Vector2.new(32, 24)

--// Normalized vector of WIND_SPEED
local WIND_DIRECTION: Vector2 = WIND_SPEED.Unit

--// The ocean, stuff such as the EditableMesh/Image are stored within
local OCEAN: MeshPart = workspace:WaitForChild("Ocean")

--// The editable mesh, used to creates waves, and to hold the foam
local OCEAN_MESH: EditableMesh

---------------CONSTANTS---------------
---------------------------------------
---------------VARIABLES---------------

--// Spectrums that will be transformed
--// into wave height/slopes
local Spectrum: {Vector2} = table.create(FURIER_SIZE*FURIER_SIZE)
local SpectrumConj: {Vector2} = table.create(FURIER_SIZE*FURIER_SIZE)

--// Used for FFT
local DisplacementBuffer: {{number}} = table.create(FURIER_SIZE*FURIER_SIZE)
local HeightBuffer: {{number}} = table.create(FURIER_SIZE*FURIER_SIZE)
local NormalBuffer: {{number}} = table.create(FURIER_SIZE*FURIER_SIZE)

--// Holds data so the spectrum can be precomputed
local Dispersions: {number} = table.create(FURIER_SIZE*FURIER_SIZE)

--// Modules
local LuaFFT = require(script.LuaFFT)

--// Services
local RunService: RunService = game:GetService("RunService")

--// For Cross Client syncing
local ServerRandom: Random = Random.new(
	math.round((workspace:GetServerTimeNow()-workspace.DistributedGameTime))
)

---------------VARIABLES--------------
--------------------------------------
---------------FUNCTIONS--------------

--// Returns a randomly distributed Guessian Vector2
local function GaussianRandomVariable(): Vector2
	local x1, x2, w

	repeat
		x1 = 2 * ServerRandom:NextNumber() - 1
		x2 = 2 * ServerRandom:NextNumber() - 1
		w = x1 * x1 + x2 * x2
	until w < 1

	w = math.sqrt((-2 * math.log(w)) / w)

	return Vector2.new(x1 * w, x2 * w)
end


--// Gets the spectrum value for the grid position
local function PhillipsSpectrum(X: number, Y: number): number
	local K: Vector2 = Vector2.new(
		math.pi * (2*X - FURIER_SIZE),
		math.pi * (2*Y - FURIER_SIZE)
	) / MESH_LENGTH

	local KLength = K.Magnitude
	if KLength < 0.000001 then
		return 0 
	end

	local KLength2: number = KLength * KLength
	local KLength4: number = KLength2 * KLength2

	K = K.Unit

	local KDotW: number = K:Dot(WIND_DIRECTION)
	local KDotW2: number = KDotW * KDotW * KDotW * KDotW * KDotW * KDotW

	local WindLength: number = WIND_SPEED.Magnitude

	local L: number = WindLength * WindLength / GRAVITY
	local L2: number = L * L

	local Damping: number = 0.001
	local l2: number = L2 * Damping * Damping

	return WAVE_AMPLITUDE * math.exp(-1 / (KLength2 * L2)) / KLength4 * KDotW2 * math.exp(-KLength2 * l2)
end


--// Gets the spectrum value for the grid position
local function GetSpectrum(X: number, Y: number): Vector2
	return GaussianRandomVariable() * math.sqrt(PhillipsSpectrum(X, Y) / 2)
end

--// Returns a dispersion number for X,Y
local function Dispersion(X: number, Y: number): number
	local w_0: number = 0.031415926535897934 -- math.pi / 100

	local kx: number = math.pi * (2 * X - FURIER_SIZE) / MESH_LENGTH
	local kz: number = math.pi * (2 * Y - FURIER_SIZE) / MESH_LENGTH

	return math.floor(math.sqrt(GRAVITY * math.sqrt(kx * kx + kz * kz)) / w_0) * w_0
end


--// Inits the spectrum for time period t
local function InitSpectrum(t: number, X: number, Y: number): Vector2
	local Index: number = Y * FURIER_SIZE + X + 1

	local OmegaT: number = Dispersions[Index] * t

	local cos: number = math.cos(OmegaT)
	local sin: number = math.sin(OmegaT)

	local c0a: number = Spectrum[Index].X*cos - Spectrum[Index].Y*sin
	local c0b: number = Spectrum[Index].X*sin + Spectrum[Index].Y*cos

	local c1a: number = SpectrumConj[Index].X*cos - SpectrumConj[Index].Y*-sin
	local c1b: number = SpectrumConj[Index].X*-sin + SpectrumConj[Index].Y*cos

	return Vector2.new(c0a+c1a, c0b+c1b)
end


--// Fills up all the required tables
local function Init()
	for Y = 0, FURIER_SIZE-1 do
		for X = 0, FURIER_SIZE-1 do
			table.insert(Dispersions, Dispersion(X, Y))

			table.insert(Spectrum, GetSpectrum(X, Y))
			table.insert(SpectrumConj, GetSpectrum(-X, -Y) * Vector2.new(1, -1))
		end
	end
end


--// Calculates the FFT and moves the vertices accordingly
local function UpdateOcean(t: number)
	task.desynchronize()
	local kx, kz, len, lambda = 0, 0, 0, -1

	--// Calculate Displacement/Height
	for Y = 0, FURIER_SIZE-1 do
		kz = math.pi * (2 * Y - FURIER_SIZE) / MESH_LENGTH

		for X = 0, FURIER_SIZE-1 do
			kx = math.pi * (2 * X - FURIER_SIZE) / MESH_LENGTH
			len = math.sqrt(kx * kx + kz * kz)

			local Index: number = Y * FURIER_SIZE + X + 1

			local c: Vector2 = InitSpectrum(t, X, Y)

			HeightBuffer[Index] = {c.Y, c.X}
			NormalBuffer[Index] = {-c.Y*kx, c.X*kx, -c.Y*kz, c.X*kz}

			if len < 0.000001 then
				DisplacementBuffer[Index] = {0, 0}
			else
				DisplacementBuffer[Index] = {
					-c.Y * -(kx/len),
					c.X * -(kx/len),
					-c.Y * -(kz/len),
					c.X * -(kz/len)
				}
			end

		end
	end
	
	--// Perform FFT
	local HeightFFT: {{number}} = LuaFFT.fft(HeightBuffer)
	local DisplacementFFT: {{number}} = LuaFFT.fft(DisplacementBuffer)
	local NormalFFT: {{number}} = LuaFFT.fft(NormalBuffer)

	task.synchronize()

	--// Transform the Vertices
	for Index, Displacement: {number} in DisplacementFFT do
		local X: number = Index // FURIER_SIZE
		local Y: number = Index % FURIER_SIZE

		-- Fixes Imag numbers being flipped
		local Sign: number = 1 - 2 * ((X + Y) % 2)

		--// Displace the Position
		OCEAN_MESH:SetPosition(Index, Vector3.new(
			X + Displacement[1] * lambda * Sign,
			HeightFFT[Index][1] * Sign,
			Y + Displacement[2] * lambda * Sign
			)
		)

		--// Change the Normal, you can change the Y value to increase/decrease strength
		OCEAN_MESH:SetVertexNormal(Index, Vector3.new(
			-NormalFFT[Index][1] * Sign,
			1,
			-NormalFFT[Index][2] * Sign
			).Unit
		)
	end
end


--//Creates a Mesh with a X,Y resolution of Furier Size
local function MakeMesh()	
	OCEAN_MESH = Instance.new("EditableMesh")

	--// Creates the Vertices, UV
	for X = 1, FURIER_SIZE do
		for Y = 1, FURIER_SIZE do
			OCEAN_MESH:AddVertex(Vector3.new(X, 0, Y))
		end
	end

	--// Connects the Vertices into Triangles
	for X = 1, FURIER_SIZE-2 do
		for Y = 1, FURIER_SIZE-2 do
			local Vertex1 = X * FURIER_SIZE + Y
			local Vertex2 = Vertex1 + 1
			local Vertex3 = (X + 1) * FURIER_SIZE + Y
			local Vertex4 = Vertex3 + 1

			OCEAN_MESH:AddTriangle(Vertex1, Vertex2, Vertex3)
			OCEAN_MESH:AddTriangle(Vertex2, Vertex4, Vertex3)
		end
	end

	OCEAN_MESH.Parent = OCEAN
end

---------------FUNCTIONS---------------
---------------------------------------
-----------------RUN-------------------

--// Creates the ocean mesh
MakeMesh()

--// Initialize the ocean
Init()

--// Update the ocean each frame
RunService.RenderStepped:Connect(function()
	UpdateOcean(workspace:GetServerTimeNow())
end)

-----------------RUN-------------------
---------------------------------------
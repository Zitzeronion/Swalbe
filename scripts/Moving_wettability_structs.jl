using DrWatson
@quickactivate :Swalbe
using CUDA, DataFrames, FileIO
# CUDA.device!(1)

# Fluid dynamics we need for the experiment
"""
    measure_substratewave

Simulates a changing wettability and the response from the film.
"""
function measure_substratewave(
    sys::Swalbe.SysConst, 
    device::String; 
    h₀ = 1.0, 
    ϵ = 0.1,
    wave_x=1,
    wave_y=1, 
    sub_speed=100,
    dump = 1000,  
    θₛ=ones(sys.Lx, sys.Ly),
    fluid=zeros(sys.param.Tmax÷dump, sys.Lx*sys.Ly),
    theta=zeros(sys.param.Tmax÷dump, sys.Lx*sys.Ly),
    dire = "x",
    verbos=true, 
    T=Float64
)
    state = Swalbe.Sys(sys, device)
    if device == "CPU"
        for i in 1:sys.Lx, j in 1:sys.Ly
            state.height[i,j] = h₀ + ϵ * sin(2π*wave_x*(i-1)/sys.Lx) * sin(2π*wave_y*(j-1)/sys.Ly)
        end
    elseif device == "GPU"
        h = zeros(size(state.height))
        for i in 1:sys.Lx, j in 1:sys.Ly
            h[i,j] = h₀ + ϵ * sin(2π*wave_x*(i-1)/sys.Lx) * sin(2π*wave_y*(j-1)/sys.Ly)
        end
        # theta = CUDA.zeros(Float64, sys.Lx, sys.Ly)
        state.height .= CUDA.adapt(CuArray, h)
    end
    Swalbe.equilibrium!(state, sys)
    for t in 1:sys.param.Tmax
        if t % sys.param.tdump == 0
            mass = 0.0
            mass = sum(state.height)
            if verbos
                println("Time step $t mass is $(round(mass, digits=3))")
            end
        end
        
        Swalbe.filmpressure!(state, sys, θ=θₛ)
        Swalbe.h∇p!(state)
        Swalbe.slippage!(state, sys)
        # Forces are the pressure gradient and the slippage due to substrate liquid boundary conditions
        state.Fx .= state.h∇px .+ state.slipx
        state.Fy .= state.h∇py .+ state.slipy
        # New equilibrium
        Swalbe.equilibrium!(state, sys)
        Swalbe.BGKandStream!(state, sys)
        # New moments
        Swalbe.moments!(state)
        # Measurements, in this case only snapshots of simulational arrays
        Swalbe.snapshot!(fluid, state.height, t, dumping = dump)
        Swalbe.snapshot!(theta, θₛ, t, dumping = dump)
        move_substrate!(state.slipx, θₛ, t, sub_speed, direction=dire)
    end
    return fluid, theta
    CUDA.reclaim()
end
# Well not most clean way but one one to freeze the substrate without having the x/0 issue.
function measure_substratewave(
    sys::Swalbe.SysConst, 
    device::String,
    move_sub::String;
    h₀ = 1.0, 
    ϵ = 0.1,
    wave_x=1,
    wave_y=1, 
    sub_speed=100,
    dump=1000,  
    θₛ=ones(sys.Lx, sys.Ly),
    fluid=zeros(sys.param.Tmax÷dump, sys.Lx*sys.Ly),
    theta=zeros(sys.param.Tmax÷dump, sys.Lx*sys.Ly),
    dire = "x",
    verbos=true, 
    T=Float64
)
    println("Simulating a time dependent substrate pattern")
    fout, ftemp, feq, height, velx, vely, vsq, pressure, dgrad, Fx, Fy, slipx, slipy, h∇px, h∇py = Swalbe.Sys(sys, device, false, T)
    if device == "CPU"
        for i in 1:sys.Lx, j in 1:sys.Ly
            height[i,j] = h₀ + ϵ * sin(2π*wave_x*(i-1)/sys.Lx) * sin(2π*wave_y*(j-1)/sys.Ly)
        end
    elseif device == "GPU"
        h = zeros(size(height))
        for i in 1:sys.Lx, j in 1:sys.Ly
            h[i,j] = h₀ + ϵ * sin(2π*wave_x*(i-1)/sys.Lx) * sin(2π*wave_y*(j-1)/sys.Ly)
        end
        # theta = CUDA.zeros(Float64, sys.Lx, sys.Ly)
        height = CUDA.adapt(CuArray, h)
    end
    Swalbe.equilibrium!(fout, height, velx, vely, vsq)
    ftemp .= fout
    for t in 1:sys.Tmax
        if t % sys.tdump == 0
            mass = 0.0
            mass = sum(height)
            if verbos
                println("Time step $t mass is $(round(mass, digits=3))")
            end
        end
        
        Swalbe.filmpressure!(pressure, height, dgrad, sys.γ, θₛ, sys.n, sys.m, sys.hmin, sys.hcrit)
        Swalbe.∇f!(h∇px, h∇py, pressure, dgrad, height)
        Swalbe.slippage!(slipx, slipy, height, velx, vely, sys.δ, sys.μ)
        # Forces are the pressure gradient and the slippage due to substrate liquid boundary conditions
        Fx .= h∇px .+ slipx
        Fy .= h∇py .+ slipy
        # New equilibrium
        Swalbe.equilibrium!(feq, height, velx, vely, vsq)
        Swalbe.BGKandStream!(fout, feq, ftemp, -Fx, -Fy)
        # New moments
        Swalbe.moments!(height, velx, vely, fout)
        # Measurements, in this case only snapshots of simulational arrays
        Swalbe.snapshot!(fluid, height, t, dumping = dump)
        Swalbe.snapshot!(theta, θₛ, t, dumping = dump)
        if move_sub == "yes"
            # move_substrate!(slipx, θₛ, t, sub_speed, direction=dire)
        end
    end
    return fluid, theta
    CUDA.reclaim()
end

function move_substrate!(θ, input, t, tmove; direction="diagonal")
    if (t % tmove == 0) & (t > 0)
        if direction == "diagonal"
            circshift!(θ, input, (1,1))
        elseif direction == "x"
            circshift!(θ, input, (1,0))
        elseif direction == "y"
            circshift!(θ, input, (0,1))
        end
        input .= θ
    end

    return nothing
end

println("Moving Wettability and possible resonaces")
speed_dict = Dict(1 => [0, 4900, 490, 49],
                  2 => [0, 9802, 980, 98],
                  3 =>  [0, 14702, 1470, 147],
                  4 => [19603, 1960, 196], 
                  5 => [24504, 2450, 245], 
                  6 => [29404, 2940, 294], 
                  7 => [34305, 3430, 343], 
                  8 => [39206, 3920, 392], 
                  9 => [44107, 4410, 441],
                  10 => 2*[24504, 2450, 245])

# To pin down the Rayleigh-Plateu instability
# v_lam2_dia_more = [490, 245, 164, 123]
for direction in ["diagonal"] #  "diagonal"
    # Different initial volumes
    waves_num = 10
    speeds = speed_dict[waves_num]
    for speed in speeds[1] # 1 2 3 # [0] 
        pattern = "sine"
        ang = 1/9
        TM = 1000 # 5000000
        println("Simulating moving substrate wettability with pattern $(pattern) and moving direction $(direction) and speed $(speed)")
        sys = Swalbe.SysConst(Lx=512, Ly=512, param=Swalbe.Taumucs(γ=0.01, δ=1.0, n=3, m=2, hmin=0.07, Tmax=TM, tdump=5000))
        #sys = Swalbe.SysConst(Lx=512, Ly=512, γ=0.01, δ=1.0, n=3, m=2, hmin=0.07, Tmax=75000, tdump=500)
        df_fluid = Dict()
        df_sub = Dict()
        θₚ = ones(sys.Lx,sys.Ly)
        # Substrate patterning
        if pattern == "sine" 
            for i in 1:sys.Lx, j in 1:sys.Ly
                θₚ[i,j] = ang + 1/18 * sin(2π*waves_num*(i-1)/sys.Lx) * sin(2π*waves_num*(j-1)/sys.Ly)
            end
        end
        # Make a cuarray with the substrate pattern
        θ_in = CUDA.adapt(CuArray, θₚ)
        if speed == 0
            # Actual simulation
            fluid, substrate = measure_substratewave(sys, "GPU", "blub", sub_speed=speed, θₛ=θ_in, dire=direction, dump=sys.param.tdump)
        else
            fluid, substrate = measure_substratewave(sys, "GPU", sub_speed=speed, θₛ=θ_in, dire=direction, dump=sys.param.tdump)
        end
        println("Writing measurements to Dict")
        # Filling the dataframes
        for t in 1:sys.param.Tmax÷sys.param.tdump
            df_fluid["h_$(t*sys.tdump)"] = fluid[t,:]
            df_sub["theta_$(t*sys.tdump)"] = substrate[t,:]
        end
        println("Saving Dict subdirection $direction subvel $speed and $(pattern) $waves_num to disk")
        save_ang = Int(round(rad2deg(π*ang)))
        save("data/Moving_wettability/height_direc_$(direction)_sp_$(speed)_$(pattern)_$(waves_num)_$(save_ang)_tmax_$(sys.param.Tmax)_v3.jld2", df_fluid)
    
        CUDA.reclaim()
    end
end

println("Script done, let's have a look at the data :)")

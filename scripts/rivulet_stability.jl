using DrWatson
@quickactivate :Swalbe
using CUDA, DataFrames, FileIO, Dates
# CUDA.device!(1)

# Fluid dynamics we need for the experiment
"""
    rivulet_run

Simulation of a thin liquid rivulet with little noise added to the interface.

Checking the stability of a liquid rivulet under the influence of different forces.
What we consider here is the athermal or deterministic case as well as the fluctuating case.
The thermal fluctuations are considered using the fluctuating thin film equation. 

# Arguments
- `sys::Swalbe.SysConst`: Simulation relevant parameter, e.g. viscosity and slip
- `device::String`: Either "CPU" or "GPU"
- `R::AbstractFloat`: Radius in (x,y)-plane of the ring structure
- `rr::AbstractFloat`: Radius in (x,z)-plane
- `ϵ::AbstractFloat`: Amplititude of the initial interface undulations
- `dump::Int`: Dumping frequency for output creation  
- `fluid::AbstractArray`: Allocation of the output array (contains the results)
- `verbos::bool`: Switch to make the simulation write to console while running

"""
function rivulet_run(
    sys::Swalbe.SysConst, 
    device::String;
    shape = :ring, 
    R = 150,
    rr = 100,
    ϵ = 0.01,
    dump = 1000,  
    fluid=zeros(sys.param.Tmax÷dump, sys.Lx*sys.Ly),
    verbos=true
)
    println("Running a simulation on rivulet stability\nThe rivulet is curved and resembles a torus")
    state = Swalbe.Sys(sys, device, kind="thermal")
    # Set up initial condition
    if shape == :ring
        h = Swalbe.torus(sys.Lx, sys.Ly, rr, R, sys.param.θ, (sys.Lx÷2, sys.Ly÷2), noise=ϵ)
    elseif shape == :rivulet
        h = Swalbe.rivulet(sys.Lx, sys.Ly, rr, sys.param.θ, :y, sys.Lx÷2, sys.param.hcrit, noise=ϵ)
    end
    # Push it to the desired device
    if device == "CPU"
        state.height .= h
    elseif device == "GPU"
        CUDA.copyto!(state.height, h)
    end
    println("Initial condition has been computed on the $(device)")
    Swalbe.equilibrium!(state, sys)
    state.ftemp .= state.fout
    println("Entering time loop")
    for t in 1:sys.param.Tmax
        if t % sys.param.tdump == 0
            mass = 0.0
            mass = sum(state.height)
            if verbos
                println("Time step $t mass is $(round(mass, digits=3))")
            end
        end
        
        Swalbe.filmpressure!(state, sys)
        Swalbe.h∇p!(state)
        Swalbe.slippage!(state, sys)
        # Forces are 
        #   - pressure gradient 
        #   - substrate friction and slippage
        #   - thermal fluctuation (if sys.param.kbt > 0)
        state.Fx .= -state.h∇px .- state.slipx .- state.kbtx
        state.Fy .= -state.h∇py .- state.slipy .- state.kbty
        # New equilibrium
        Swalbe.equilibrium!(state, sys)
        Swalbe.BGKandStream!(state, sys)
        # New moments
        Swalbe.moments!(state)
        # Measurements, in this case only snapshots of simulational arrays
        Swalbe.snapshot!(fluid, state.height, t, dumping = dump)
    end
    return fluid
    CUDA.reclaim()
end

# Set up the simulation 
timeInterval = 25000

# Make a parameter sweep
for kb in [0.0, 1e-6]
    sys = Swalbe.SysConst(512, 512, Swalbe.Taumucs(Tmax=5000000, kbt=kb, n=3, m=2))
    for outerRad in [30, 50, 80]
            for innerRad in [80, 120]
                    # Run the simulation
                    fluid = rivulet_run(sys, "GPU", R=100, rr=80, dump=timeInterval)
                    df_fluid = Dict()
                    nSnapshots = sys.param.Tmax ÷ timeInterval
                    for t in 1:nSnapshots
                        println("In saving loop at $(t) with $(size(fluid[t,:]))")
                        df_fluid["h_$(t * timeInterval)"] = fluid[t,:]
                    end

                    println("Saving rivulet snapshots for R=$(outerRad) and r=$(innerRad) to disk")
                    save_ang = Int(round(rad2deg(π*sys.param.θ)))
                    file_name = "data/Rivulets/height_R_$(outerRad)_r_$(innerRad)_ang_$(save_ang)_kbt_$(sys.param.kbt)_nm_$(sys.param.n)-$(sys.param.m)_runDate_$(year(today()))_$(month(today()))_$(day(today()))_$(hour(now()))_$(minute(now())).jld2"
                    save(file_name, df_fluid)
                    CUDA.reclaim()
                end
            end
        end
    end
end
@testset "Allocations" begin
    sys = Swalbe.SysConst{Float64}(Lx=25, Ly=26)
    fout, ftemp, feq, height, velx, vely, pressure, Fx, Fy, slipx, slipy, h∇px, h∇py, fthermalx, fthermaly = Swalbe.Sys(sys, "CPU", true)
    # Struct should do what I expect, hopefully
    @test sys.Lx == 25
    @test sys.Ly == 26
    @test isa(fout, Array{Float64, 3})
    @test isa(ftemp, Array{Float64, 3})
    @test isa(feq, Array{Float64, 3})
    @test isa(height, Array{Float64, 2})
    @test isa(velx, Array{Float64, 2})
    @test isa(vely, Array{Float64, 2})
    @test isa(pressure, Array{Float64, 2})
    @test isa(Fx, Array{Float64, 2})
    @test isa(Fy, Array{Float64, 2})
    @test isa(slipx, Array{Float64, 2})
    @test isa(slipy, Array{Float64, 2})
    @test isa(h∇px, Array{Float64, 2})
    @test isa(h∇py, Array{Float64, 2})
    @test isa(fthermalx, Array{Float64, 2})
    @test isa(fthermaly, Array{Float64, 2})
    fout, ftemp, feq, height, velx, vely, pressure, Fx, Fy, slipx, slipy, h∇px, h∇py, = Swalbe.Sys(sys, "CPU", false)
    # Struct should do what I expect, hopefully
    @test sys.Lx == 25
    @test sys.Ly == 26
    @test isa(fout, Array{Float64, 3})
    @test isa(ftemp, Array{Float64, 3})
    @test isa(feq, Array{Float64, 3})
    @test isa(height, Array{Float64, 2})
    @test isa(velx, Array{Float64, 2})
    @test isa(vely, Array{Float64, 2})
    @test isa(pressure, Array{Float64, 2})
    @test isa(Fx, Array{Float64, 2})
    @test isa(Fy, Array{Float64, 2})
    @test isa(slipx, Array{Float64, 2})
    @test isa(slipy, Array{Float64, 2})
    @test isa(h∇px, Array{Float64, 2})
    @test isa(h∇py, Array{Float64, 2})
end
@testset "Collision and Stream" begin
    @testset "Dummy dists τ=1 no forces" begin
        feq = ones(5,5,9)
        ftemp = ones(5,5,9)
        fout = ones(5,5,9)
        feq[1,1,:] .= 2.0
        Swalbe.BGKandStream!(fout, feq, ftemp, zeros(5,5), zeros(5,5))
        @test all(fout[:,:,1] .== feq[:,:,1])
        @test all(fout[:,:,2] .== circshift(feq[:,:,1],(1,0)))
        @test all(fout[:,:,3] .== circshift(feq[:,:,1],(0,1)))
        @test all(fout[:,:,4] .== circshift(feq[:,:,1],(-1,0)))
        @test all(fout[:,:,5] .== circshift(feq[:,:,1],(0,-1)))
        @test all(fout[:,:,6] .== circshift(feq[:,:,1],(1,1)))
        @test all(fout[:,:,7] .== circshift(feq[:,:,1],(-1,1)))
        @test all(fout[:,:,8] .== circshift(feq[:,:,1],(-1,-1)))
        @test all(fout[:,:,9] .== circshift(feq[:,:,1],(1,-1)))
    end
    @testset "Dummy dists τ=0.75 no forces" begin
        feq = ones(5,5,9)
        ftemp = ones(5,5,9)
        fout = ones(5,5,9)
        feq[1,1,:] .= 2.0
        onebytau = 1.0/0.75
        omega = 1.0 - 1.0/0.75
        Swalbe.BGKandStream!(fout, feq, ftemp, zeros(5,5), zeros(5,5), 0.75)
        @test all(fout[:,:,1] .== omega .* 1.0 .+ onebytau .* feq[:,:,1])
        @test all(fout[:,:,2] .≈ circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(1,0)))
        @test all(fout[:,:,3] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(0,1)))
        @test all(fout[:,:,4] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(-1,0)))
        @test all(fout[:,:,5] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(0,-1)))
        @test all(fout[:,:,6] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(1,1)))
        @test all(fout[:,:,7] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(-1,1)))
        @test all(fout[:,:,8] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(-1,-1)))
        @test all(fout[:,:,9] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(1,-1)))
    end
    @testset "Dummy dists τ=1 with forces" begin
        feq = ones(5,5,9)
        ftemp = ones(5,5,9)
        fout = ones(5,5,9)
        feq[1,1,:] .= 2.0
        Swalbe.BGKandStream!(fout, feq, ftemp, fill(0.1,5,5), fill(-0.1,5,5))
        @test all(fout[:,:,1] .== feq[:,:,1])
        @test all(fout[:,:,2] .== circshift(feq[:,:,1] .+ 1/30,(1,0)))
        @test all(fout[:,:,3] .== circshift(feq[:,:,1] .- 1/30,(0,1)))
        @test all(fout[:,:,4] .== circshift(feq[:,:,1] .- 1/30,(-1,0)))
        @test all(fout[:,:,5] .== circshift(feq[:,:,1] .+ 1/30,(0,-1)))
        @test all(fout[:,:,6] .== circshift(feq[:,:,1],(1,1)))
        @test all(fout[:,:,7] .== circshift(feq[:,:,1] .- 1/24 .* 0.2 ,(-1,1)))
        @test all(fout[:,:,8] .== circshift(feq[:,:,1],(-1,-1)))
        @test all(fout[:,:,9] .== circshift(feq[:,:,1] .+ 1/24 .* 0.2,(1,-1)))
    end
    @testset "Dummy dists τ=0.75 with forces" begin
        feq = ones(5,5,9)
        ftemp = ones(5,5,9)
        fout = ones(5,5,9)
        feq[1,1,:] .= 2.0
        onebytau = 1.0/0.75
        omega = 1.0 - 1.0/0.75
        Swalbe.BGKandStream!(fout, feq, ftemp, fill(0.1,5,5), fill(-0.1,5,5), 0.75)
        @test all(fout[:,:,1] .== omega .* 1.0 .+ onebytau .* feq[:,:,1])
        @test all(fout[:,:,2] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1].+ 1/30,(1,0)))
        @test all(fout[:,:,3] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1].- 1/30,(0,1)))
        @test all(fout[:,:,4] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1].- 1/30,(-1,0)))
        @test all(fout[:,:,5] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1].+ 1/30,(0,-1)))
        @test all(fout[:,:,6] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(1,1)))
        @test all(fout[:,:,7] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1] .- 1/24 .* 0.2,(-1,1)))
        @test all(fout[:,:,8] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1],(-1,-1)))
        @test all(fout[:,:,9] .== circshift(omega .* 1.0 .+ onebytau * feq[:,:,1] .+ 1/24 .* 0.2,(1,-1)))
    end
end

@testset "viewdists" begin
    f = reshape(collect(1.0:225.0),5,5,9)
    f0, f1, f2, f3, f4, f5, f6, f7, f8 = Swalbe.viewdists(f)
    allviews = [f0, f1, f2, f3, f4, f5, f6, f7, f8]
    for (index, value) in enumerate(allviews)
        @test all(value .== f[:,:,index])
    end
end
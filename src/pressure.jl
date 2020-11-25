"""
    filmpressure!(pressure, height, γ, θ, n, m, hmin, hcrit)

Calculation of the capillary pressure which is given by `` p = - γ∇²h+ Π(h) ``.

# Arguments

- `pressure :: Array{Number,2}`: Array that store the result of the compuation
- `height :: Array{Number,2}`: Height field ``h(\\mathbf{x},t)``
- `γ <: Number`: Forcing strenght due to surface tension
- `θ <: Number`: Equilibrium contact angle
- `n :: Int`: Larger power law exponent for `` Π(h) ``
- `m :: Int`: Smaller power law exponent for `` Π(h) ``
- `hmin <: Number`: Parameter of `` Π(h) ``, in fact `` Π(hmin) = 0 ``
- `hcrit <: Number`: Numerical stabilizer for case `` h(\\mathbf{x},t) \\ll hmin ``

# Mathematics

The capillary pressure ``p_{\\text{cap}}`` is the centeral angle to match our model with the thin film equation.
It consists of two parts, first being the laplace pressure `` \\nabla^2 h `` and second being the derivative of the disjoining pontential `` \\Pi(h) ``

`` p_{\\text{cap}} = -\\gamma \\nabla^2 h + \\Pi(h). ``

For the laplacian term we use the same nine point discretization as in `Swlabe.∇²f!`.
`` \\Pi(h) `` on the other hand is given by 

`` \\Pi(h) = \\kappa(\\theta)f(h), ``

where `` \\kappa(\\theta) `` is simply a measure for the **Hamaker constant** and given as

`` \\kappa(\\theta) = \\gamma(1- \\cos(\\theta))\\frac{(n-1)(m-1)}{(n-m)h_{\\text{min}}}.``

For `` f(h) `` one can use various forms, a very common however is the power law given by 

`` f(h) = \\bigg[\\bigg(\\frac{h_{\\text{min}}}{h}\\bigg)^n - \\bigg(\\frac{h_{\\text{min}}}{h}\\bigg)^m\\bigg]. ``

# Examples

```jldoctest
julia> using Swalbe, Test

julia> h = reshape(collect(1.0:25.0),5,5) # A dummy height field
5×5 Array{Float64,2}:
 1.0   6.0  11.0  16.0  21.0
 2.0   7.0  12.0  17.0  22.0
 3.0   8.0  13.0  18.0  23.0
 4.0   9.0  14.0  19.0  24.0
 5.0  10.0  15.0  20.0  25.0

julia> pressure = zeros(5,5); θ = 0.0; # Fully wetting substrate

julia> Swalbe.filmpressure!(pressure, h, θ) # default γ = 0.01

julia> result = [30.0 5.0 5.0 5.0 -20;
                 25.0 0.0 0.0 0.0 -25.0;
                 25.0 0.0 0.0 0.0 -25.0;
                 25.0 0.0 0.0 0.0 -25.0;
                 20.0 -5.0 -5.0 -5.0 -30.0];

julia> for i in eachindex(result)
           @test result[i] .≈ -100 .* pressure[i] atol=1e-12
       end
```

# References

- [Peschka et al.](https://www.pnas.org/content/116/19/9275)
- [Craster and Matar](https://journals.aps.org/rmp/abstract/10.1103/RevModPhys.81.1131)
- [Derjaguin and Churaev](https://www.sciencedirect.com/science/article/abs/pii/0021979778900565)

"""
function filmpressure!(output, f, γ, θ, n, m, hmin, hcrit)
    # Straight elements j+1, i+1, i-1, j-1
    hip = circshift(f, (1,0))
    hjp = circshift(f, (0,1))
    him = circshift(f, (-1,0))
    hjm = circshift(f, (0,-1))
    # Diagonal elements  
    hipjp = circshift(f, (1,1))
    himjp = circshift(f, (-1,1))
    himjm = circshift(f, (-1,-1))
    hipjm = circshift(f, (1,-1))
    # Disjoining pressure part
    κ = (1 - cospi(θ)) * (n-1) * (m-1) / ((n-m)*hmin) 

    output .= -γ .* ((2/3 .* (hjp .+ hip .+ him .+ hjm) 
                   .+ 1/6 .* (hipjp .+ himjp .+ himjm .+ hipjm) 
                   .- 10/3 .* f) .- κ .* (power_broad.(hmin./(f .+ hcrit), n)  
                                       .- power_broad.(hmin./(f .+ hcrit), m)))
    return nothing
end
# Standard usage parameters
function filmpressure!(output, f, θ)
    # Straight elements j+1, i+1, i-1, j-1
    hip = circshift(f, (1,0))
    hjp = circshift(f, (0,1))
    him = circshift(f, (-1,0))
    hjm = circshift(f, (0,-1))
    # Diagonal elements  
    hipjp = circshift(f, (1,1))
    himjp = circshift(f, (-1,1))
    himjm = circshift(f, (-1,-1))
    hipjm = circshift(f, (1,-1))
    # Disjoining pressure part
    κ = (1 - cospi(θ)) * 16/0.6 

    output .= -0.01 .* ((2/3 .* (hjp .+ hip .+ him .+ hjm) 
                   .+ 1/6 .* (hipjp .+ himjp .+ himjm .+ hipjm) 
                   .- 10/3 .* f) .- κ .* (power_broad.(0.1./(f .+ 0.05), 9)  
                                       .- power_broad.(0.1./(f .+ 0.05), 3)))
    return nothing
end

"""
    power_broad(arg, n)

Computes `arg` to the power `n`.

Actually this is useful because the `^` operator is much slower.
Same thing I learned about the `pow` function in **C**, * yes it does what you want, but it is slow as fuck *.

# Examples
```jldoctest
julia> using Swalbe, Test

julia> Swalbe.power_broad(3, 3)
27

julia> Swalbe.power_broad.([2.0 5.0 6.0], 2) # Use the broadcasting operator `.`
1×3 Array{Float64,2}:
 4.0  25.0  36.0

```

See also: [`filmpressure`](@ref)
"""
function power_broad(arg::Float64, n::Int)
    temp = 1.0
    for i = 1:n
        temp *= arg
    end
    return temp
end

function power_broad(arg::Float32, n::Int)
    temp = 1.0f0
    for i = 1:n
        temp *= arg
    end
    return temp
end

function power_broad(arg::Int, n::Int)
    temp = 1
    for i = 1:n
        temp *= arg
    end
    return temp
end
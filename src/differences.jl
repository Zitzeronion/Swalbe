"""
    ∇²f!(output, f, γ)

Finite difference operator for a second derivative in two dimensions.

Computes the laplacian of an input `f` times a scalar `γ` and stores the result in `output`.

# Mathematics

The laplacian operator in two dimensions can be written as

`` \\nabla^2 f = \\frac{\\partial^2 f}{\\partial x^2} + \\frac{\\partial^2 f}{\\partial y}. ``

For the discretization of this operator we use a nine point stencil, such the neighbors as well as the diagonal elements.
The concrete derivation can be found in the references below, we just show the final result

``\\nabla^2 f = \\frac{1}{6}\\bigg[4(f_{i+1,j} + f_{i,j+1} + f_{i-1,j} + f_{i,j-1}) \\newline
                \\qquad\\qquad +(f_{i+1,j+1} + f_{i-1,j+1} + f_{i-1,j-1} + f_{i+1,j-1}) \\newline
                \\qquad\\qquad -20f_{i,j}\\bigg]  ,``

where we have used Julia conventions, downwards (left) is positive. 
The whole expression can be multiplied with a scalar `γ` if needed.

# Examples

```jldoctest
julia> using Swalbe, Test

julia> arg = reshape(collect(1.0:25),5,5)
5×5 Array{Float64,2}:
 1.0   6.0  11.0  16.0  21.0
 2.0   7.0  12.0  17.0  22.0
 3.0   8.0  13.0  18.0  23.0
 4.0   9.0  14.0  19.0  24.0
 5.0  10.0  15.0  20.0  25.0

julia> res = zeros(5,5); Swalbe.∇²f!(res, arg, -1.0)

julia> analytics = [-30.0 -5.0 -5.0 -5.0 20;
                    -25.0 0.0 0.0 0.0 25.0;
                    -25.0 0.0 0.0 0.0 25.0;
                    -25.0 0.0 0.0 0.0 25.0;
                    -20.0 5.0 5.0 5.0 30.0];

julia> for i in eachindex(analytics)
           @test analytics[i] ≈ res[i] atol=1e-10
       end
```

# References

- [Junk & Klar](https://epubs.siam.org/doi/10.1137/S1064827599357188)
- [Succi et al.](https://doi.org/10.1016/j.jcp.2012.07.037)

See also: [`Swalbe.∇f!`](@ref)
"""
function ∇²f!(output, f, γ)
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
    # In the end it is just a weighted sum...
    output .= γ .* (2/3 .* (hjp .+ hip .+ him .+ hjm) 
                  .+ 1/6 .* (hipjp .+ himjp .+ himjm .+ hipjm) 
                  .- 10/3 .* f)
    return nothing
end

"""
    ∇f!(outputx, outputy, f)

Gradient calculation with finite differences.

Computes both spatial first derivatives with a nine point stencil from an input `f` and writes the result to `outputx` and `outputy`.
Since broadcasting is simple on the **GPU** we make use of `circshift` for the neighbors.

# Mathematics

The gardient in two dimensions is given as

`` \\nabla f = \\big(\\frac{\\partial f}{\\partial x}, \\frac{\\partial f}{\\partial y}\\big)^T .``

Again with the nine point stencil this reduces to 

`` \\frac{\\partial f}{\\partial x} = \\frac{1}{3} (f_{i+1,j} - f_{i-1,j}) + \\frac{1}{12}(f_{i+1,j+1} - f_{i-1,j+1} - f_{i-1,j-1} + f_{i+1,j-1}) ,``

and for the `y` component we get

`` \\frac{\\partial f}{\\partial y} = \\frac{1}{3} (f_{i,j+1} - f_{i,j-1}) + \\frac{1}{12}(f_{i+1,j+1} + f_{i-1,j+1} - f_{i-1,j-1} - f_{i+1,j-1}) .``

For the exact derivation feel free to read the reference by Junk and Klar.

# Examples
```jldoctest
julia> using Swalbe, Test

julia> arg = reshape(collect(1.0:25),5,5)
5×5 Array{Float64,2}:
 1.0   6.0  11.0  16.0  21.0
 2.0   7.0  12.0  17.0  22.0
 3.0   8.0  13.0  18.0  23.0
 4.0   9.0  14.0  19.0  24.0
 5.0  10.0  15.0  20.0  25.0

julia> resx = zeros(5,5); resy = zeros(5,5); Swalbe.∇f!(resx, resy, arg)

julia> whatXshouldbe = [-1.5 -1.5 -1.5 -1.5 -1.5;
                         1.0 1.0 1.0 1.0 1.0;
                         1.0 1.0 1.0 1.0 1.0;
                         1.0 1.0 1.0 1.0 1.0;
                        -1.5 -1.5 -1.5 -1.5 -1.5];

julia> for i in eachindex(resx) # Test the x-component
           @test resx[i] ≈ whatXshouldbe[i] atol=1e-10
       end

julia> whatYshouldbe = [-7.5 5.0 5.0 5.0 -7.5;
                        -7.5 5.0 5.0 5.0 -7.5;
                        -7.5 5.0 5.0 5.0 -7.5;
                        -7.5 5.0 5.0 5.0 -7.5;
                        -7.5 5.0 5.0 5.0 -7.5];

julia> for i in eachindex(resy) # Test the y-component
           @test resy[i] ≈ whatYshouldbe[i] atol=1e-10
       end
```

# References

- [Junk & Klar](https://epubs.siam.org/doi/10.1137/S1064827599357188)
- [Succi et al.](https://doi.org/10.1016/j.jcp.2012.07.037)

See also: [`Swalbe.∇²f!`](@ref)
"""
function ∇f!(outputx, outputy, f)
    # Straight elements j+1, i+1, i-1, j-1
    fip = circshift(f, (1,0))
    fjp = circshift(f, (0,1))
    fim = circshift(f, (-1,0))
    fjm = circshift(f, (0,-1))
    # Diagonal elements  
    fipjp = circshift(f, (1,1))
    fimjp = circshift(f, (-1,1))
    fimjm = circshift(f, (-1,-1))
    fipjm = circshift(f, (1,-1))
    # In the end it is just a weighted sum...
    outputx .= -1/3 .* (fip .- fim) .- 1/12 .* (fipjp .- fimjp .- fimjm .+ fipjm)
    outputy .= -1/3 .* (fjp .- fjm) .- 1/12 .* (fipjp .+ fimjp .- fimjm .- fipjm)

    return nothing
end

function ∇f!(outputx, outputy, f, a)
    # Straight elements j+1, i+1, i-1, j-1
    fip = circshift(f, (1,0))
    fjp = circshift(f, (0,1))
    fim = circshift(f, (-1,0))
    fjm = circshift(f, (0,-1))
    # Diagonal elements  
    fipjp = circshift(f, (1,1))
    fimjp = circshift(f, (-1,1))
    fimjm = circshift(f, (-1,-1))
    fipjm = circshift(f, (1,-1))
    # In the end it is just a weighted sum...
    outputx .= a .* (-1/3 .* (fip .- fim) .- 1/12 .* (fipjp .- fimjp .- fimjm .+ fipjm))
    outputy .= a .* (-1/3 .* (fjp .- fjm) .- 1/12 .* (fipjp .+ fimjp .- fimjm .- fipjm))

    return nothing
end
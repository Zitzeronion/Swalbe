var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Swalbe","category":"page"},{"location":"#Swalbe","page":"Home","title":"Swalbe","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [Swalbe]","category":"page"},{"location":"#Swalbe.filmpressure!-NTuple{8,Any}","page":"Home","title":"Swalbe.filmpressure!","text":"filmpressure!(output, f, γ, θ, n, m, hmin, hcrit)\n\n\n\n\n\n","category":"method"},{"location":"#Swalbe.power_broad-Tuple{Float64,Int64}","page":"Home","title":"Swalbe.power_broad","text":"power_broad(arg, n)\n\nComputes arg to the power n.\n\nSee also: filmpressure\n\n\n\n\n\n","category":"method"},{"location":"#Swalbe.∇f!-Tuple{Any,Any,Any}","page":"Home","title":"Swalbe.∇f!","text":"∇f!(outputx, outputy, f)\n\nGradient calculation with finite differences.\n\nComputes both spatial first derivatives with a nine point stencil from an input f and writes the result to outputx and outputy.\n\nMathematics\n\nThe gardient in two dimensions is given as\n\nnabla f = big(fracpartial fpartial x fracpartial fpartial ybig)^T \n\nAgain with the nine point stencil this reduces to \n\nfracpartial fpartial x = frac13 (f_i+1j - f_i-1j) + frac112(f_i+1j+1 - f_i-1j+1 - f_i-1j-1 + f_i+1j-1) \n\nand for the y component we get\n\nfracpartial fpartial y = frac13 (f_ij+1 - f_ij-1) + frac112(f_i+1j+1 + f_i-1j+1 - f_i-1j-1 - f_i+1j-1) \n\nFor the exact derivation feel free to read the reference by Junk and Klar.\n\nExamples\n\njulia> using Swalbe, Test\n\njulia> arg = reshape(collect(1.0:25),5,5)\n5×5 Array{Float64,2}:\n 1.0   6.0  11.0  16.0  21.0\n 2.0   7.0  12.0  17.0  22.0\n 3.0   8.0  13.0  18.0  23.0\n 4.0   9.0  14.0  19.0  24.0\n 5.0  10.0  15.0  20.0  25.0\n\njulia> resx = zeros(5,5); resy = zeros(5,5); Swalbe.∇f!(resx, resy, arg)\n\njulia> whatXshouldbe = [-1.5 -1.5 -1.5 -1.5 -1.5;\n                         1.0 1.0 1.0 1.0 1.0;\n                         1.0 1.0 1.0 1.0 1.0;\n                         1.0 1.0 1.0 1.0 1.0;\n                        -1.5 -1.5 -1.5 -1.5 -1.5];\n\njulia> for i in eachindex(resx) # Test the x-component\n           @test resx[i] ≈ whatXshouldbe[i] atol=1e-10\n       end\n\njulia> whatYshouldbe = [-7.5 5.0 5.0 5.0 -7.5;\n                        -7.5 5.0 5.0 5.0 -7.5;\n                        -7.5 5.0 5.0 5.0 -7.5;\n                        -7.5 5.0 5.0 5.0 -7.5;\n                        -7.5 5.0 5.0 5.0 -7.5];\n\njulia> for i in eachindex(resy) # Test the y-component\n           @test resy[i] ≈ whatYshouldbe[i] atol=1e-10\n       end\n\nReferences\n\nJunk & Klar\nSucci et al.\n\nSee also: Swalbe.∇²f!\n\n\n\n\n\n","category":"method"},{"location":"#Swalbe.∇²f!-Tuple{Any,Any,Any}","page":"Home","title":"Swalbe.∇²f!","text":"∇²f!(output, f, γ)\n\nFinite difference operator for a second derivative in two dimensions.\n\nComputes the laplacian of an input f times a scalar γ and stores the result in output.\n\nMathematics\n\nThe laplacian operator in two dimensions can be written as\n\nnabla^2 f = fracpartial^2 fpartial x^2 + fracpartial^2 fpartial y\n\nFor the discretization of this operator we use a nine point stencil, such the neighbors as well as the diagonal elements. The concrete derivation can be found in the references below, we just show the final result\n\nnabla^2 f = frac16bigg4(f_i+1j + f_ij+1 + f_i-1j + f_ij-1) newline                 qquadqquad +(f_i+1j+1 + f_i-1j+1 + f_i-1j-1 + f_i+1j-1) newline                 qquadqquad -20f_ij+1bigg  \n\nwhere we have used Julia conventions, downwards (left) is positive.  The whole expression can be multiplied with a scalar γ if needed.\n\nExamples\n\njulia> using Swalbe, Test\n\njulia> arg = reshape(collect(1.0:25),5,5)\n5×5 Array{Float64,2}:\n 1.0   6.0  11.0  16.0  21.0\n 2.0   7.0  12.0  17.0  22.0\n 3.0   8.0  13.0  18.0  23.0\n 4.0   9.0  14.0  19.0  24.0\n 5.0  10.0  15.0  20.0  25.0\n\njulia> res = zeros(5,5); Swalbe.∇²f!(res, arg, -1.0)\n\njulia> analytics = [-30.0 -5.0 -5.0 -5.0 20;\n                    -25.0 0.0 0.0 0.0 25.0;\n                    -25.0 0.0 0.0 0.0 25.0;\n                    -25.0 0.0 0.0 0.0 25.0;\n                    -20.0 5.0 5.0 5.0 30.0];\n\njulia> for i in eachindex(analytics)\n           @test analytics[i] ≈ res[i] atol=1e-10\n       end\n\nReferences\n\nJunk & Klar\nSucci et al.\n\nSee also: Swalbe.∇f!\n\n\n\n\n\n","category":"method"}]
}

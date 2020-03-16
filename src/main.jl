using JuMP, Gurobi
using DelimitedFiles

include("data.jl")
include("bnp.jl")
include("mip.jl")

const GUROBI_ENV = Gurobi.Env()
global data = read_data("CCNFP10g1a.txt")
global ϵ = 0.00001

result = solve_MIP()
result = solve_BnP()

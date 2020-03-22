using JuMP, Gurobi
using DelimitedFiles

include("data.jl")
include("bnp.jl")
include("mip.jl")

const GUROBI_ENV = Gurobi.Env()
global data = read_data("test.txt")
global ϵ = 0.00001

#solve_BnP()
solve_MIP()

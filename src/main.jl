using JuMP, Gurobi
using DelimitedFiles

include("src/data.jl")
include("src/bnp.jl")
include("src/mip.jl")

const GUROBI_ENV = Gurobi.Env()

global branching_rule = "generic"
global subproblem_method = "gurobi"
global root_heuristic = "None"
global tree_heuristic = false
global queueing_method = "FIFO"
global verbose_level = 3
global ϵ = 0.00001

global data = read_data("Falkenauer/Falkenauer_T/Falkenauer_t60_10.txt")

solve_BnP()

#solve_MIP()

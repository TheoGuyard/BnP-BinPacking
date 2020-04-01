using JuMP, Gurobi
using DelimitedFiles

include("data.jl")
include("bnp.jl")
include("mip.jl")

const GUROBI_ENV = Gurobi.Env()

global branching_rule = "ryan_foster"
global subproblem_method = "gurobi"
global root_heuristic = "FFD"
global tree_heuristic = false
global queueing_method = "FIFO"
global verbose_level = 3
global ϵ = 0.000001

global data = read_data("Falkenauer/Falkenauer_T/Falkenauer_t60_10.txt")

solve_BnP()
#solve_MIP()

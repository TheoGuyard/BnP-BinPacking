using JuMP, Gurobi
using DelimitedFiles

include("data.jl")
include("bnp.jl")
include("mip.jl")

const GUROBI_ENV = Gurobi.Env()

global branching_rule = "ryan_foster"
global subproblem_method = "gurobi"
global root_heuristic = false
global tree_heuristic = false
global queueing_method = "FIFO"
global verbose_level = 1
global ϵ = 0.00001

global data = read_data("test.txt")

solve_BnP()
#solve_MIP()

using JuMP, Gurobi
using DelimitedFiles, Dates

include("data.jl")
include("bnp.jl")
include("mip.jl")
include("benchmarks.jl")

# Informations about each parameter are given in the README.md file
const GUROBI_ENV = Gurobi.Env()
global branching_rule = "generic"
global subproblem_method = "dynamic"
global root_heuristic = "BFD"
global tree_heuristic = "BRUSUC"
global queueing_method = "FIFO"
global verbose_level = 3
global ϵ = 0.00001
global maxTime = 60

### Solve a unique problem ###

global data = read_data("data/Falkenauer/Falkenauer_T/Falkenauer_t60_00.txt")

solve_BnP()
#solve_MIP()

### Benchmark on multiple problems gathered in a directory ###

#benchmarksDirectory = "data/Falkenauer/Falkenauer_T/"
#maxItems = 101
#benchmarks(benchmarksDirectory, maxItems)

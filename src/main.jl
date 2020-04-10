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
global root_heuristic = "FFD"
global tree_heuristic = false
global queueing_method = "FIFO"
global verbose_level = 3
global ϵ = 0.000001

### Solve a unique problem ###

global data = read_data("data/Falkenauer/Falkenauer_T/Falkenauer_t60_01.txt")
solve_BnP()
#solve_MIP()

### Benchmark on multiple problems gathered in a directory ###

#benchmarksDirectory = "data/Falkenauer/Falkenauer_T"
#maxItems = 60
#maxTime = 30
#benchmarks(benchmarksDirectory, maxItems, maxTime)

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
global tree_heuristic = "BRUSUC"
global queueing_method = "Hybrid"
global verbose_level = 2
global ϵ = 0.00001
global maxTime = 100000000

### Solve a unique problem ###

global data = read_data("data/Falkenauer/Falkenauer_T/Falkenauer_t120_00.txt")
solve_BnP()
solve_MIP()

### Benchmark on multiple problems gathered in a directory ###

#benchmarksDirectory = "data/Scholl/Scholl_1/"
#maxItems = 200
#benchmarks(benchmarksDirectory, maxItems)

using JuMP, Gurobi
using DelimitedFiles, Dates, DataFrames, CSV

include("data.jl")
include("bnp.jl")
include("mip.jl")

function benchmarks(datasetDirectory, maxItems, maxTime)

  println("\e[92m************ Benchmarks ***************\e[00m")

    global verbose_level = 0
    
    benchmarks = DataFrame(
      ID = String[],
      capacity = Int[],
      nbItems = Int[],
      branchingRule = String[],
      subproblemMethod = String[],
      rootHeuristic = String[],
      treeHeuristic = Bool[],
      queueingMethod = String[],
      ϵ = Float32[],
      objectiveValue = Float32[],
      rootHeuristicObjective = Float32[],
      nbNodesExplored = Int[],
      runningTime = Float32[]
    )

  for dataset in readdir(datasetDirectory)
    
    global data = read_data(joinpath(datasetDirectory, dataset))

    if data.N > maxItems
      continue
    end

    println("\e[36mBenchmark on file : $dataset\e[00m")
    objectiveValue, rootHeuristicObjective, nbNodeExplored, runningTime = solve_BnP(maxTime, true)

    push!(benchmarks, 
      [data.ID,
      data.C,
      data.N,
      branching_rule,
      subproblem_method,
      root_heuristic,
      tree_heuristic,
      queueing_method,
      ϵ,
      objectiveValue, 
      rootHeuristicObjective, 
      nbNodeExplored, 
      runningTime]
    )
  end

  title = Dates.format(now(), "dd:u:yyyy-HH:MM")
  CSV.write("results/benchmarks/$(title).csv",  benchmarks, writeheader=true)

  return nothing

end
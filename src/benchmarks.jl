using JuMP, Gurobi
using DelimitedFiles, Dates, DataFrames, CSV

include("data.jl")
include("bnp.jl")
include("mip.jl")

function benchmarks(datasetDirectory, maxItems)
  """Run the BnP on each file contained in the <datasetDirectory> if the dataset has
  less than <maxItems> items in it. The BnP stops if the <maxTime> is reached."""

  println("\e[92m************ Benchmarks ***************\e[00m")

  global verbose_level = 0

  # Benchmarks results are stored in a DataFrame
  benchmarks = DataFrame(
    ID = String[],
    capacity = Int[],
    nbItems = Int[],
    branchingRule = String[],
    subproblemMethod = String[],
    rootHeuristic = String[],
    treeHeuristic = String[],
    queueingMethod = String[],
    ϵ = Float32[],
    objectiveValue = Float32[],
    gap = Float32[],
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
    objectiveValue, gap, rootHeuristicObjective, nbNodeExplored, runningTime = solve_BnP(true)

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
      gap,
      rootHeuristicObjective,
      nbNodeExplored,
      runningTime]
    )
  end

  # Write the benchmark in a textfile with the datetime as title
  title = Dates.format(now(), "dd:u:yyyy-HH:MM")
  CSV.write("results/benchmarks/$(title).csv", benchmarks, writeheader=true)

  return nothing

end

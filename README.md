# Branch-and-Price for the Bin-Packing problem

**Author** : Théo Guyard

**Description** : Work done during my 4th school year at INSA Rennes in the Mathematics Department. The aim was to solve the Bin Packing problem using a Branch and Price algorithm.

**Language** : `Julia 1.4`

**Dependencies** : `JuMP`, `Gurobi`, `DelimitedFiles`, `Dates`, `CSV`, `DataFrames`


---

## Features

- [x] Ryan & Foster branching rule
- [x] Generic branching rule
- [x] Root heuristics (FFD, BFD, WFD)
- [x] Tree heuristics (MIRUP and rounding based)
- [x] FIFO, LIFO and Hybrid queuing rules
- [x] Dynamic programming for Generic branching rule
- [x] Different display levels
- [x] Benchmarks
- [ ] Dynamic programming for Ryan & Foster branching rule
- [ ] Diving heuristic strategy

## Usage

1. Clone the repository
```
    git clone git://github.com/TheoGuyard/BnP-BinPacking.git
```
2. Open `Julia` or an IDE at **project root** (directory containing `README.md`)
3. Intall dependencies
```
    (@v1.4) pkg> add JuMP, Gurobi, DelimitedFiles, Dates, CSV, DataFrames
```
4. Make sure that [Gurobi environment variable](https://github.com/JuliaOpt/Gurobi.jl) is set
```
    julia> ENV["GUROBI_HOME"] = "/path/to/gurobi/lib"
```
5. Set the parameters and run the code in `main.jl`

To run the code for a single dataset, it is possible to use either the `solve_BnP()` method (to use the BnP algorithm) or to use the `solve_MIP()` method (to use only Gurobi on the classical BPP formulation). The dataset must be set in the `data` variable with its **relative path** from the root directory and using the `read_data` method. For example :
```
    global data = read_data("data/Falkenauer/Falkenauer_T/Falkenauer_t60_00.txt")
```

It is also possible to run the code on several datasets to benchmark the method. The directory of the datasets to test is set in the `benchmarksDirectory` variable with its  **relative path** from the root directory. It is possible to set the maximum number of items wanted in the datasets to test. The benchmark can be run with the `benchmark()` method. The following example run a benchmark on the `Scholl_1` directory but only with datasets with at most 100 items :
```
    benchmarksDirectory = "data/Scholl/Scholl_1/"
    maxItems = 100
    benchmarks(benchmarksDirectory, maxItems)
```

## Settings

The following parameters are set in `main.jl`. More details are given in the **[technical report](tex/report.pdf)**.

* `branching_rule` : `"ryan_foster"` or `"generic"`
* `subproblem_method` : `"gurobi"` or `"dynamic"`
* `root_heuristic` : `"FFD"`, `"WFD"`, `"BFD"` or `"None"`
* `tree_heuristic` : `"MIRUP"`, `"BRUSIM"`, `"BRURED"`, `"BOPT"`, `"BRUSUC"`, `"CSTAOPT"`, `"None"`
* `queueing_method` : `"FIFO"`, `"LIFO"` or `"Hybrid"`
* `verbose_level` : `1`, `2` or `3`
* `ϵ` : Between `10e(-16)` and `10e(-4)`
* `maxTime` : Maximum solving time allowed in seconds

It is not possible to set both `branching_rule = "ryan_foster"` and `subproblem_method = "dynamic"` as no dynamic programming methods are implemented for this branching scheme.

## Datasets

Bin-Packing datasets come from [BPPLIB](http://or.dei.unibo.it/library/bpplib).

* [Falkenauer dataset](https://link.springer.com/article/10.1007/BF00226291) : Divided into two classes of 80 instances each : the first class has uniformly distributed item sizes (‘Falkenauer U’) with n between 120 and 1000, and c = 150. The instances of the second class (‘Falkenauer T’) includes the so-called triplets, i.e., groups of three items (one large, two small) that need to be assigned to the same bin in any optimal packing, with n between 60 and 501, and c = 1000.
* [Scholl dataset](https://www.sciencedirect.com/science/article/abs/pii/S0305054896000822) : Divided into three sets of 720, 480, and 10, respectively, uniformly distributed instances with n between 50 and 500. The capacity c is between 100 and 150 (set ‘Scholl 1’), equal to 1000 (set ‘Scholl 2’), and equal to 100 000 (set ‘Scholl 3’), respectively.

Two small test datasets are also provided. If an other dataset is used, make sure that the file is under the `.bpp` format.

## Code file description

File discribed below are in the folder `src/`.

* `main.jl` : Parameter initialization and code entry
* `bnp.jl` : Branch-and-Price core structure
* `master.jl` : Restricted master problem resolution method
* `node.jl` : Core structure of node processing resolution
* `subproblem.jl` : Subproblem resolution method
* `knapsack.jl` : Knapsack problem solving methods
* `root_heurisitcs.jl` : Root heuristic algorithms used before the Branch-and-Price algorithm
* `tree_heurisitcs.jl` : Tree heuristic algorithms used within the Branch-and-Price algorithm
* `benchmarks.jl` : Run benchmarks for a given dataset directory
* `display.jl` : Display algorithm results
* `data.jl` : Read data from dataset file
* `typedef.jl` : Type definition used in the algorithm
* `mip.jl` : Mixed Integer Programming formulation to solve the problem with Gurobi

For more information on the implementation, see the comments directly on the code or take a look at the **[technical report](tex/report.pdf)** 😁.

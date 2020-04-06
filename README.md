# Branch-and-Price for the Bin-Packing problem


**Language** : `Julia 1.4`

**Dependencies** : `JuMP`, `Gurobi`, `DelimitedFiles`, `Dates`, `CSV`, `DataFrames`

---

## Usage

1. Clone the repository
```
    git clone git://github.com/TheoGuyard/BnP-BinPacking.git
```
2. Open `Julia` or an IDE at project in (directory containing `README.md`)
3. Intall dependencies
```
    (@v1.4) pkg> add JuMP, Gurobi, DelimitedFiles
```
4. Make sure that [Gurobi environement variable](https://github.com/JuliaOpt/Gurobi.jl) is set
```
    julia> ENV["GUROBI_HOME"] = "/path/to/gurobi/lib"
```
5. Set the parameters and run the code in `main.jl`

## Settings

The following parameters are set in `main.jl`. More details are given in the **[technical report](tex/report.pdf)**.

* `branching_rule` : `"ryan_foster"` or `"generic"`
* `subproblem_method` : `"gurobi"` or `"dynamic"`
* `root_heuristic` : `"FFD"`, `"WFD"`, `"BFD"` or `"None"`
* `tree_heuristic` : `true` or `false`
* `queueing_method` : `"FIFO"` or `"LIFO"`
* `verbose_level` : `1`, `2` or `3`
* `ϵ` : Between `10e(-16)` and `10e(-4)`

## Datasets

Bin-Packing datasets come from [BPPLIB](http://or.dei.unibo.it/library/bpplib). 

* [Falkenauer dataset](https://link.springer.com/article/10.1007/BF00226291) : Divided into two classes of 80 instances each : the first class has uniformly distributed item sizes (‘Falkenauer U’) with n between 120 and 1000, and c = 150. The instances of the second class (‘Falkenauer T’) includes the so-called triplets, i.e., groups of three items (one large, two small) that need to be assigned to the same bin in any optimal packing, with n between 60 and 501, and c = 1000.
* [Scholl dataset](https://www.sciencedirect.com/science/article/abs/pii/S0305054896000822) : Divided into three sets of 720, 480, and 10, respectively, uniformly distributed instances with n between 50 and 500. The capacity c is between 100 and 150 (set ‘Scholl 1’), equal to 1000 (set ‘Scholl 2’), and equal to 100 000 (set ‘Scholl 3’), respectively.

If an other dataset is used, make sure that the file is under the `.BPP` format.

## Code file description

File discribed below are in the folder `Bnp-BinPacking/src/`.

* `main.jl` : Parameter initialization and code entry
* `bnp.jl` : Branch-and-Price core structure
* `master.jl` : Resticted master problem resolution method
* `node_ryan_foster.jl` : Node processing the Ryan & Foster branching rule
* `subproblem_ryan_foster.jl` : Subproblem resolution method for the Ryan & Foster branching rule
* `node_generic.jl` : Node processing the generic branching rule
* `subproblem_generic.jl` : Subproblem resolution method for the generic branching rule
* `heurisitcs.jl` : Heuristic algorithms used within the Branch-and-Price algorithm
* `display.jl` : Display algorithm results
* `data.jl` : Read data from dataset file
* `typedef.jl` : New type defiinition used in the algorithm
* `mip.jl` : Mixed Integer Programming formulation to solve the problem with Gurobi 

## Benchmarks

## ToDo

- [x] Ryan & Foster branching rule
- [x] Generic branching rule
- [x] Root heuristics
- [x] FIFO and LIFO queuing rule 
- [x] Set verbose level
- [ ] Dynamic programming for Ryan & Foster branching rule
- [ ] Dynamic programming for Generic branching rule
- [ ] Benchmarks
- [ ] Heuristics within tree
- [ ] Diving search strategy

function read_data(instance::AbstractString)

  # Datasets are under .BPP format :
    # - Fisrt line : number of items
    # - Second line : bin capacity
    # - Lines 3 to N+2 : item size

  data = Data()
  file = readdlm(string(dirname(@__FILE__),"/../data/", instance),'\n')

  println("\e[92m******** Read instance file **********\e[00m")

  data.ID = split(instance, "/")[end]
  data.N = file[1]
  data.C = file[2]
  data.S = file[3:(data.N+2)]
  data.B = data.N

  println("Instance : $(data.ID)")
  println("Bin capacity : $(data.C)")
  println("Number of items : $(data.N)")

  println("\e[92m************* Settings ***************\e[00m")
  println("Branching rule : $branching_rule")
  println("Subproblem method : $subproblem_method")
  println("Heuristic at root : $root_heuristic")
  println("Heuristic throughout tree : $tree_heuristic")
  println("Queueing method : $queueing_method")
  println("Verbose level : $verbose_level")

  return data
end

mutable struct Data
  ID::String                    # Problem ID
  C::Float32                    # Bin capacity
  N::Int                        # Number of items
  best_bin::Int                 # Number ob bins in the best solution known
  B::Int                        # Upper bound on bin number
  S::Array{Float32}             # Item size
  Data() = new()
end

mutable struct Node
  parent::Int                   # Parent's node index
  children::Vector{Int}         # Children's node index
  lb::Float32                   # Node lower bound
  upbranch::Array{Tuple}        # Couple of items for up-branch rules
  downbranch::Array{Tuple}      # Couple of items for down-branch rules
end

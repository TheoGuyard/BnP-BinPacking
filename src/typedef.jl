mutable struct Data
    ID::String      # Problem ID
    C::Int          # Bin capacity
    N::Int          # Number of items
    B::Int          # Upper bound on bin number
    S::Array{Int}   # Item size
    Data() = new()
end

mutable struct SubproblemRules
    setzero::Vector{Int}    # Items set to zero in the subproblem
    setone::Vector{Int}     # Items set to one in the subproblem
end

mutable struct Node
    parent::Int                                 # Index of the parent node
    children::Vector{Int}                       # Indexes of the children nodes
    lb::Float32                                 # Node lower bound
    upbranch::Array{Tuple}                      # Couple of items involved in a up-branching rule
    downbranch::Array{Tuple}                    # Couple of items involved in a down-branching rule
    subproblem_rules::Array{SubproblemRules}   # Subproblems rules (only used for the generic branching rule)
end

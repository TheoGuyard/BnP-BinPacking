mutable struct Data
    ID::String      # Problem ID
    C::Int          # Bin capacity
    N::Int          # Number of items
    B::Int          # Upper bound on bin number
    S::Array{Int}   # Item size
    Data() = new()
end

mutable struct Rule
    setzero::Vector{Int}    # Items set to zero in the rule
    setone::Vector{Int}     # Items set to one in the rule
    Rule() = new([],[])     # Constructor
    Rule(setzero, setone) = new(setzero, setone)
end

mutable struct SubproblemSet
    rules::Array{Rule}                          # Branching rules for the subproblem set
    coeff::Int                                  # Coefficient for the redundance constraint
    SubproblemSet() = new([Rule()], data.B)     # Constructor
    SubproblemSet(rules, coeff) = new(rules, coeff)
end

mutable struct Node
    parent::Int                                     # Index of the parent node
    children::Array{Int}                            # Indexes of the children nodes
    lb::Float32                                     # Node lower bound
    upBranch::Array{Tuple}                          # Couple of items involved in a up-branching rule
    downBranch::Array{Tuple}                        # Couple of items involved in a down-branching rule
    subproblemSets::Array{SubproblemSet}            # Subproblems sets (only used for the generic branching rule)
    Node() = new(0,[],-Inf,[],[],[SubproblemSet()]) # Constructor
    Node(parent,children,lb,upBranch,downBranch,subproblemSets) = new(parent,children,lb,upBranch,downBranch,subproblemSets)
end

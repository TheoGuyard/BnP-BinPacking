include("master.jl")

function solve_heuristic_master(nodesol, fix_to_zero, fix_to_one, integer=false, L=data.B)
    """Solve the resticted master problem with some heuristically fixed variables."""

    heuristic_master = Model(with_optimizer(Gurobi.Optimizer, GUROBI_ENV, OutputFlag = 0))
    if integer
        alpha = @variable(heuristic_master, alpha[p in 1:size(nodesol, 1)], Bin)
    else
        alpha = @variable(heuristic_master, alpha[p in 1:size(nodesol, 1)], lower_bound = 0)
    end
    packed = @constraint(
        heuristic_master,
        packed[i in 1:data.N],
        sum(nodesol[p][i+1] * alpha[p] for p = 1:size(nodesol, 1)) >= 1
    )
    redundant = @constraint(heuristic_master, redundant, sum(alpha[p] for p = 1:size(nodesol, 1)) <= L)
    fixed_zero = @constraint(heuristic_master, fixed_zero[i in fix_to_zero],
        alpha[i] <= 0)
    fixed_one = @constraint(heuristic_master, fixed_one[i in fix_to_one],
        alpha[i] >= 1)
    @objective(heuristic_master, Min, sum(alpha[p] for p = 1:size(nodesol, 1)))
    optimize!(heuristic_master)

    if (L != data.B) && (JuMP.termination_status != MOI.OPTIMAL)
        return []
    end

    alpha = JuMP.value.(alpha)
    for p in 1:size(nodesol,1)
        nodesol[p][1] = alpha[p]
    end

    return nodesol

end

function mirup(nodesol)
    """Solve the master problem with integrity constraint with an
    MIRUP bound on the number of pattern allowned."""

    mirup_bound = ceil(sum(p[1] for p in nodesol)) + 1
    solution = solve_heuristic_master(nodesol, [], [], true, mirup_bound)
    return solution

end

function brusim(nodesol)
    """Simple round-up-to-one heuristic strategy."""

    for p in nodesol
        p[1] = ceil(p[1])
    end

    return nodesol
end

function brured(nodesol)
    """Round-up-to-one and cost reduction heuristic strategy."""

    round_up_solution = brusim(nodesol)

    reduced = true
    while reduced
        for s in 1:size(round_up_solution, 1)
            already_packed = true
            for i in 1:data.N
                if [1 for p in round_up_solution if p[i+1] > 0] == []
                    already_packed = false
                    break
                end
            end
            if already_packed
                deleteat!(round_up_solution, s)
                reduced = true
                break
            end
        end
        reduced = false
    end

    return round_up_solution
end

function bopt(nodesol)
    """Solve with integrity constraint the master problem with the restricted solution
    as column pool."""

    solve_heuristic_master(nodesol, [], [], true)

    return nodesol
end

function brusuc(nodesol)
    """Successive rounding strategy with reoptimization of the restricted master."""

    fix_to_zero = []
    fix_to_one = []

    # Fix the variables that are already integer
    for p in 1:size(nodesol,1)
        if nodesol[p][1] == 0
            push!(fix_to_zero, p)
        elseif nodesol[p][1] == 1
            push!(fix_to_one, p)
        end
    end

    # While the solution is not integer
    while any(p -> p[1] - floor(p[1]) > ϵ, nodesol)

        # Fix the fractional variable closest to one
        max_frac = 0
        max_frac_ind = 0
        for p in 1:size(nodesol,1)
            col_cost = nodesol[p][1]
            if (col_cost - floor(col_cost) > ϵ) && (col_cost > max_frac)
                max_frac = col_cost
                max_frac_ind = p
            end
        end
        push!(fix_to_one, max_frac_ind)

        # Reoptimize the restricted master
        nodesol = solve_heuristic_master(nodesol, fix_to_zero, fix_to_one)

    end

    return nodesol
end

function find_cutting_pattern(nodesol)
    """Find a pattern in oversuply."""

    for p in 1:size(nodesol,1), i in 1:data.N
        if nodesol[p][i+1] * nodesol[p][1]> 0
            if sum(pt[i+1] * pt[1] for pt in nodesol) > 1
                nodesol[p][1] = 0
                return nodesol, true
            end
        end
    end

    return nodesol, false
end

function cstaopt(nodesol)
    """Composite heuristic with first a brusuc heuristic, then oversupply patterns
    are removed and the remaining residual problem is solved."""

    nodesol = brusuc(nodesol)

    cutting_pattern_found = true
    while cutting_pattern_found
        nodesol, cutting_pattern_found = find_cutting_pattern(nodesol)
    end

    fix_to_one = [p for p in 1:size(nodesol, 1) if nodesol[p][1] == 1]

    nodesol = solve_heuristic_master(nodesol, [], fix_to_one, true)

    return nodesol

end

function process_tree_heuristic(nodesol)
    """Process an heuristic using the current node solution to improve the
    global UB."""

    if tree_heuristic == "None"
        return nothing
    end

    # Chose the heuristic to process
    if tree_heuristic == "MIRUP"
        solution = mirup(nodesol)
    elseif tree_heuristic == "BRUSIM"
        solution = brusim(nodesol)
    elseif tree_heuristic == "BRURED"
        solution = brured(nodesol)
    elseif tree_heuristic == "BOPT"
        solution = bopt(nodesol)
    elseif tree_heuristic == "BRUSUC"
        solution = brusuc(nodesol)
    elseif tree_heuristic == "CSTAOPT"
        solution = cstaopt(nodesol)
    end

    # Get the solution and the cost in a proper format
    if solution != []
        heuristic_sol = Array{Array{Float32},1}()
        for c in 1:size(solution,1)
            if solution[c][1] >= ϵ push!(heuristic_sol, solution[c]) end
        end
        heuristic_cost = sum(p[1] for p in heuristic_sol)
    else
        heuristic_sol = []
        heuristic_cost = Inf
    end

    # Update the best solution and the global UB if needed and if the heuristic
    # solution is feasible
    if verbose_level >= 3 println("\e[36m Heuristic solution with cost $heuristic_cost found\e[00m") end
    if heuristic_cost < UB
        if verbose_level >= 3 println("\e[36m Best solution updated with the heuristic solution\e[00m") end
        global UB = heuristic_cost
        global bestsol = heuristic_sol
    end

end

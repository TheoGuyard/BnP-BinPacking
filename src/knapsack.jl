function solve_knapsack(profits, weights, capacity)
    """Dynamicaly solve the classical knapsack problem."""

    nb_items = length(weights)
    table = zeros(nb_items+1, capacity+1)

    # Compute optimal cost
    for j in 1:nb_items
        for Y in 1:capacity
            if weights[j] > Y
                table[j+1,Y+1] = table[j,Y+1]
            else
                table[j+1,Y+1] = max(table[j,Y+1], profits[j] + table[j,Y-weights[j]+1])
            end
        end
    end
    cost = table[end,end]

    # Backtraking to find items involved in the optimal cost
    solution = zeros(nb_items)
    j = capacity + 1
    for i in (nb_items+1):-1:2
        if table[i,j] != table[i-1,j]
            solution[i-1] = 1
            j = j - weights[i-1]
        end
    end

    return cost, solution

end

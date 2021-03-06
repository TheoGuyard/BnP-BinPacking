function display_mip_result(obj, u, x, status, solvingTime)

    if verbose_level >= 1
        # Print to console
        println("\e[92m********** MIP results **************\e[00m")
        println("Terminaison status : $status")
        println("Number of bin used : $obj")
        println("Solving time : $solvingTime")
        for b = 1:data.B
            if sum(x[:, b]) >= 1
                print("Bin $b contains objects : ")
                for i = 1:data.N
                    if x[i, b] == 1
                        print("$i ")
                    end
                end
                println("")
            end
        end
    end

    # Print to file
    instance = split(data.ID, ".")[1]
    open("results/single_dataset/$(instance)_MIP.txt", "w") do f
        write(f, "****** Problem ******\n")
        write(f, "Instance : $(data.ID)\n")
        write(f, "Bin capacity : $(data.C)\n")
        write(f, "Number of items : $(data.N)\n")
        write(f, "Method : MIP\n")
        write(f, "****** Settings ******\n")
        write(f, "Branching rule : $branching_rule\n")
        write(f, "Subproblem method : $subproblem_method\n")
        write(f, "Root heuristic : $root_heuristic\n")
        write(f, "Tree heuristic : $tree_heuristic\n")
        write(f, "Queueing method : $queueing_method\n")
        write(f, "Verbose level : $verbose_level\n")
        write(f, "****** Result ******\n")
        write(f, "Solving time : $solvingTime seconds\n")
        write(f, "Number of bin used : $obj\n")
        for b = 1:data.B
            if sum(x[:, b]) >= 1
                write(f, "Bin $b contains objects : ")
                for i = 1:data.N
                    if x[i, b] == 1
                        write(f, "$i ")
                    end
                end
                write(f, "\n")
            end
        end
    end

end

function display_bnp_result(bestsol, runningTime)

    if verbose_level >= 1
        # Print to console
        println("\e[92m********** BnP results **************\e[00m")
        println("Running time : $runningTime seconds")
        println("Nodes explored : $nbNodeExplored")
        println("Root heursitic objective : $rootHeuristicObjective")
        println("Number of bin used : $UB")
        for b = 1:size(bestsol, 1)
            print("Bin $b contains objects : ")
            for i = 1:data.N
                if bestsol[b][i+1] == 1
                    print("$i ")
                end
            end
            println("")
        end
    end

    # Print to file
    instance = split(data.ID, ".")[1]
    open("results/single_dataset/$(instance)_BnP.txt", "w") do f
        write(f, "****** Problem ******\n")
        write(f, "Instance : $(data.ID)\n")
        write(f, "Bin capacity : $(data.C)\n")
        write(f, "Number of items : $(data.N)\n")
        write(f, "Method : Branch-and-Price\n")
        write(f, "****** Settings ******\n")
        write(f, "Branching rule : $branching_rule\n")
        write(f, "Subproblem method : $subproblem_method\n")
        write(f, "Root heuristic : $root_heuristic\n")
        write(f, "Tree heuristic : $tree_heuristic\n")
        write(f, "Queueing method : $queueing_method\n")
        write(f, "Verbose level : $verbose_level\n")
        write(f, "****** Result ******\n")
        write(f, "Running time : $runningTime seconds\n")
        write(f, "Nodes explored : $nbNodeExplored\n")
        write(f, "Root heursitic objective : $rootHeuristicObjective\n")
        write(f, "Number of bin used : $UB\n")
        for b = 1:size(bestsol, 1)
            write(f, "Bin $b contains objects : ")
            for i = 1:data.N
                if bestsol[b][i+1] == 1
                    write(f, "$i ")
                end
            end
            write(f, "\n")
        end
    end

end

import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `fact_testing.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- fact_testing.m
-- Benchmark factorial implementations: built-in, prod(1:n), for-loop, and recursive.
-- Measures average time per call over N repetitions using tic/toc.
-- Times saved in vector "times" for plotting.

function fact_testing()
    n = 100; -- Factorial argument (adjust as needed)
    N = 1e5; -- Number of calls for averaging (large for accuracy)

    -- this allows me to save on itterations for data that alreay exists in variables
    -- allowing me to focus on plotting (graphing) issues
    compute = true;
    if evalin("base", "exist('fact_times', 'var')")
        prompt = "Timing variables exist in workspace. Use existing (y) or recompute (n)? ";
        answer = input(prompt, "s");
        if strcmpi(answer, "y")
            times = evalin("base", "fact_times");
            n = evalin("base", "fact_n");
            N = evalin("base", "fact_N");
            compute = false;
        end
    end

    if compute
        disp("Timing built-in factorial...");
        tic;
        for i = 1:N
            factorial(n);
        end
        t_builtin = toc / N;
        disp("Done timing built-in factorial.");

        disp("Timing prod(1:n)...");
        tic;
        for i = 1:N
            prod(1:n);
        end
        t_prod = toc / N;
        disp("Done timing prod(1:n).");

        disp("Timing for-loop factorial...");
        tic;
        for i = 1:N
            fact_for(n);
        end
        t_for = toc / N;
        disp("Done timing for-loop factorial.");

        disp("Timing recursive factorial...");
        tic;
        for i = 1:N
            fact_recursive(n);
        end
        t_recursive = toc / N;
        disp("Done timing recursive factorial.");

        disp("Saving times to vector...");
        times = [t_builtin, t_prod, t_for, t_recursive];
        disp("Done saving times.");

        assignin("base", "fact_n", n);
        assignin("base", "fact_N", N);
        assignin("base", "fact_times", times);
    end

    disp("Plotting results...");
    toolkits = available_graphics_toolkits();
    if any(strcmp(toolkits, "gnuplot"))
        graphics_toolkit("gnuplot");
    elseif any(strcmp(toolkits, "fltk"))
        graphics_toolkit("fltk");
    elseif any(strcmp(toolkits, "qt"))
        graphics_toolkit("qt");

    else
        disp("No graphics toolkit available. Plotting skipped.");
        return;
    end
    bar(times);
    xticklabels({"Built-in", "Prod", "For-loop", "Recursive"});
    xlabel("Method");
    ylabel("Average time per call (s)");
    title(["Timing for n = ", num2str(n), ", N = ", num2str(N)]);
    drawnow; -- Force plot rendering
    disp("Plot displayed. Press Enter to continue.");
    pause; -- Hold figure open until Enter is pressed
end

-- Subfunctions
function f = fact_for(k)
    f = 1;
    for j = 2:k
        f = f * j;
    end
end

function f = fact_recursive(k)
    if k > 0
        f = k * fact_recursive(k-1);
    else
        f = 1;
    end
end
}

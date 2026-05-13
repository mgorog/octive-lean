import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `pig_latin_hw2.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- big_script.m: Combined script for Pig Latin translation and Falling Object Plot

-- Part 1: Pig Latin Translation
disp("--- Pig Latin Translation ---");

-- Prompt user for input
word = input("Enter an English word: ", "s");

-- Convert to lowercase
word = lower(word);

-- Get the first letter
first = word(1);

-- Check if first letter is a vowel
if first == "a" || first == "e" || first == "i" || first == "o" || first == "u"
    -- Append "way" if vowel
    pig_latin = [word, "way"];
else
    -- Find the position of the first vowel
    vowels = ["a", "e", "i", "o", "u"];
    first_vowel_pos = 0;
    for i = 2:length(word)
        if any(word(i) == vowels)
            first_vowel_pos = i;
            break;
        end
    end

    -- If no vowel found (rare, but handle it), treat as consonant cluster
    if first_vowel_pos == 0
        pig_latin = [word, "ay"];
    else
        -- Move consonants to end and append "ay"
        consonants = word(1:first_vowel_pos-1);
        rest = word(first_vowel_pos:numel(word));
        pig_latin = [rest, consonants, "ay"];
    end
end

-- Print the result
disp(["Pig Latin: ", pig_latin]);

-- Part 2: Falling Object Plot and Results
disp("--- Falling Object Results ---");

-- Prompt for final time
tf = input("Enter final time (in seconds): ");

-- Call the function
[t, v, s] = fallingObjectPlot(tf);

-- Print sample results (first 5 and last 5 for brevity if arrays are long)
disp("Time (t) array sample:");
disp(t(1:min(5, length(t))));
if length(t) > 5
    disp("...");
    disp(t(numel(t)-4:numel(t)));
end

disp("Velocity (v) array sample:");
disp(v(1:min(5, length(v))));
if length(v) > 5
    disp("...");
    disp(v(numel(v)-4:numel(v)));
end

disp("Position (s) array sample:");
disp(s(1:min(5, length(s))));
if length(s) > 5
    disp("...");
    disp(s(numel(s)-4:numel(s)));
end

-- Function definition (placed at the end as per MATLAB/Octave convention for scripts with functions)
function [t, v, s] = fallingObjectPlot(tf)
    -- fallingObjectPlot: Plots position and velocity of a falling object versus time
    -- Input:
    --   tf = final time (in seconds)
    -- Outputs:
    --   t = array of times at which position and velocity are computed (seconds)
    --   v = array of velocities (meters/second)
    --   s = array of positions (meters)
    --
    -- Assumptions: Constant gravity, no air resistance. Position starts at 0.
    -- Modifications:
    -- - Added position calculation (s = 0.5 * g * t^2)
    -- - Stacked subplots: position (green) on top, velocity (red) on bottom
    -- - Added axis labels with units and grid lines

    g = 9.81;  -- Acceleration due to gravity (m/s^2)

    -- Calculation Section:
    dt = tf / 500;  -- Time step for smooth plot
    t = 0:dt:tf;    -- Time array (seconds)
    v = g * t;      -- Velocity array (m/s)
    s = 0.5 * g * t.^2;  -- Position array (m) - integrated from velocity

    -- Output/Plot Section:
    figure;  -- New figure window

    -- Position plot (top subplot, green)
    subplot(2,1,1);
    plot(t, s, "g", "LineWidth", 1.5);
    xlabel("Time (seconds)");
    ylabel("Position (meters)");
    grid on;

    -- Velocity plot (bottom subplot, red)
    subplot(2,1,2);
    plot(t, v, "r", "LineWidth", 1.5);
    xlabel("Time (seconds)");
    ylabel("Velocity (m/s)");
    grid on;
end
}

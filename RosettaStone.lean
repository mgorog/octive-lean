import OctiveLean
import OctiveLean.DSL

/-!
# OctiveLean Rosetta Stone — DSL edition

Octave is now a first-class Lean 4 syntax category. The LSP recognizes
keywords, operators, and structure inside `octave! { ... }` blocks.

Syntax differences from standard Octave:
  • Outer block:  `octave! { ... }`
  • Block terminators: `endif` / `endfor` / `endwhile` / `endswitch` /
                       `end_try_catch` / `endfunction`  (Octave-valid keywords)
  • Strings:  `"..."`  (Lean style)
  • Comments: `--`     (Lean style — `%` is the modulo operator token)
  • Matrices: `[1.0, 2.0; 3.0, 4.0]`  (commas for cols, `;` for rows)
-/

open OctiveLean DSL

-- §1  LITERALS
octave! {
  disp(3.14)
  disp(42)
  disp("hello")
  disp(true)
}

-- §2  ASSIGNMENT
octave! {
  x = 42;
  disp(x)
}

-- §3  ARITHMETIC
octave! {
  a = 10;
  b = 3;
  disp(a + b)
  disp(a - b)
  disp(a * b)
  disp(a / b)
  disp(a ^ b)
  disp(a .* b)
  disp(a ./ b)
  disp(a .^ b)
}

-- §4  COMPARISON & LOGICAL
octave! {
  disp(3 < 5)
  disp(3 <= 3)
  disp(3 == 3)
  disp(3 != 4)
  disp(1 && 0)
  disp(1 || 0)
}

-- §5  UNARY
octave! {
  disp(- 5)
  disp(! true)
}

-- §6  MATRIX LITERALS
octave! {
  row = [1, 2, 3, 4, 5];
  M = [1, 2, 3; 4, 5, 6; 7, 8, 9];
  disp(size(M))
}

-- §7  RANGES
octave! {
  r = 1 : 5;
  disp(length(r))
}

-- §8  IF / ELSEIF / ELSE
octave! {
  x = 7;
  if x > 10
    disp("big")
  elseif x > 5
    disp("medium")
  else
    disp("small")
  endif
}

-- §9  FOR LOOP
octave! {
  s = 0;
  for k = 1 : 5
    s = s + k;
  endfor
  disp(s)
}

-- §10  WHILE LOOP
octave! {
  n = 1;
  while n < 32
    n = n * 2;
  endwhile
  disp(n)
}

-- §11  FUNCTION DEFINITION
octave! {
  function y = square(x)
    y = x .^ 2;
  endfunction
  disp(square(7))
}

-- §12  RECURSIVE FUNCTION  (factorial)
octave! {
  function y = fact(n)
    if n <= 1
      y = 1;
    else
      y = n * fact(n - 1);
    endif
  endfunction
  disp(fact(6))
}

-- §13  TRY / CATCH
octave! {
  try
    disp(undefined_xyz)
  catch e
    disp("caught an error")
  end_try_catch
}

-- §14  BUILTINS — math
octave! {
  disp(sqrt(2))
  disp(abs(- 5))
  disp(sin(0))
  disp(cos(0))
  disp(exp(1))
  disp(log(exp(1)))
  disp(floor(3.7))
  disp(ceil(3.2))
  disp(mod(17, 5))
  disp(max([3, 1, 4, 1, 5]))
  disp(min([3, 1, 4, 1, 5]))
  disp(sum([1, 2, 3, 4, 5]))
  disp(mean([1, 2, 3, 4, 5]))
  disp(norm([3, 4]))
}

-- §15  BIND THE PARSED AST AS A LEAN TERM (for proof interop)
octave_program! mySumProgram {
  s = 0;
  for k = 1 : 10
    s = s + k;
  endfor
  disp(s)
}

#check mySumProgram   -- : Array OctiveLean.Stmt
#eval mySumProgram.size

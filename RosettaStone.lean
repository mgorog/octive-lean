import OctiveLean

/-!
# OctiveLean Rosetta Stone  (DSL edition)

Octave code written directly as Lean syntax — no strings, no raw AST.
The `octave! ... octave_end` macro compiles to typed `OctiveLean.Stmt`
values at elaboration time, so the LSP highlights keywords, operators,
and structure just like any other Lean code.

Block-closer differences from standard Octave (all are valid in real Octave too):
  `endif`  `endfor`  `endwhile`  `endfunction`  `endswitch`  `endtry`

Outer block:  `octave! ... octave_end`
-/

-- ─────────────────────────────────────────────────────────────────
-- §1  LITERALS
-- ─────────────────────────────────────────────────────────────────

octave!
  disp(3.14)
  disp(42)
  disp("hello")
  disp(true)
  disp(false)
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §2  VARIABLES — assignment and lookup
-- ─────────────────────────────────────────────────────────────────

-- Semicolon = silent; no semicolon = echoes the value
octave!
  x = 42;
  disp(x)
octave_end

octave!
  a = 10
  b = 20;
  disp(a + b)
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §3  ARITHMETIC OPERATORS
-- ─────────────────────────────────────────────────────────────────

octave!
  a = 10;  b = 3;
  disp(a + b)     -- 13
  disp(a - b)     -- 7
  disp(a * b)     -- 30
  disp(a / b)     -- 3.333…
  disp(a ^ b)     -- 1000
  disp(a .* b)    -- 30  element-wise
  disp(a ./ b)    -- 3.333…
  disp(a .^ b)    -- 1000
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §4  COMPARISON & LOGICAL
-- ─────────────────────────────────────────────────────────────────

octave!
  disp(3 < 5)    -- 1
  disp(3 <= 3)   -- 1
  disp(5 > 3)    -- 1
  disp(5 >= 6)   -- 0
  disp(3 == 3)   -- 1
  disp(3 != 4)   -- 1
  disp(1 && 0)   -- 0   short-circuit AND
  disp(1 || 0)   -- 1   short-circuit OR
  disp(1 & 0)    -- 0   element-wise AND
  disp(1 | 0)    -- 1   element-wise OR
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §5  UNARY OPERATORS
-- ─────────────────────────────────────────────────────────────────

octave!
  disp(-5)       -- negation
  disp(!true)    -- logical not → 0
  v = [1.0, 2.0, 3.0];
  disp(v)
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §6  MATRIX LITERALS
--     [a, b, c]            row vector
--     [[a, b], [c, d]]     matrix (rows are inner arrays)
-- ─────────────────────────────────────────────────────────────────

octave!
  row = [1.0, 2.0, 3.0, 4.0, 5.0]
  M   = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]]
  eigenvalues(M)
  E   = []
  disp(size(M))
  disp([1,2,3]*M)
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §7  CELL ARRAYS
-- ─────────────────────────────────────────────────────────────────

-- Note: cell array syntax uses the raw AST path for now;
-- the `{ }` token is not yet wired in the DSL syntax category.
-- See RosettaStone.lean (string edition) for the string-based version.

-- ─────────────────────────────────────────────────────────────────
-- §8  RANGES   a:b   and   a:step:b
-- ─────────────────────────────────────────────────────────────────

octave!
  r1 = 1:5;               -- 1 2 3 4 5
  r2 = 0.0:0.5:2.0;       -- 0.0 0.5 1.0 1.5 2.0  (a:step:b via (a:step):b parse)
  r3 = 5.0: -1.0 :1.0;    -- 5 4 3 2 1
  disp(r1)
  disp(length(r1))
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §9  INDEXING   A(i, j)
-- ─────────────────────────────────────────────────────────────────

octave!
  A = [[10.0, 20.0, 30.0], [40.0, 50.0, 60.0]];
  disp(A(1, 2))    -- 20
  disp(A(2, 1))    -- 40
  disp(A(1, 3))    -- 30
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §10  STRUCT FIELDS   s.field   and   s.(expr)
-- ─────────────────────────────────────────────────────────────────

octave!
  p.x = 3.0;
  p.y = 4.0;
  disp(p.x)          -- 3
  disp(p.y)          -- 4
octave_end

-- Note: p.(field) dynamic field access works as a standalone statement,
-- but not nested inside another call like disp(p.(field)) due to Lean's
-- ".(" single-token ambiguity inside argument lists.

-- ─────────────────────────────────────────────────────────────────
-- §11  FUNCTION HANDLES   @name   and   @(args) expr
-- ─────────────────────────────────────────────────────────────────

octave!
  f = @sin;
  disp(f(3.14159./4))               -- 0

  g = @(x) x .^ 2.0 + 1.0;
  disp(g(3.0))               -- 10

  h = @(x, y) x + y;
  disp(h(10.0, 5.0))         -- 15
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §12  IF / ELSEIF / ELSE / ENDIF
-- ─────────────────────────────────────────────────────────────────

octave!
  x = 7.0;
  if x > 10.0
    disp("big")
  elseif x > 5.0
    disp("medium")
  else
    disp("small")
  endif
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §13  FOR / ENDFOR
-- ─────────────────────────────────────────────────────────────────

octave!
  s = 0.0;
  for k = 1:5
    s = s + k;
  endfor
  disp(s)    -- 15
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §14  WHILE / ENDWHILE
-- ─────────────────────────────────────────────────────────────────

octave!
  n = 1.0;
  while n < 32.0
    n = n * 2.0;
  endwhile
  disp(n)    -- 32
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §15  BREAK  /  CONTINUE
-- ─────────────────────────────────────────────────────────────────

octave!
  for k = 1:10
    if k == 4.0
      break
    endif
  endfor
  disp(k)    -- 4

  s = 0.0;
  for k = 1:5
    if mod(k, 2.0) == 0.0
      continue
    endif
    s = s + k;
  endfor
  disp(s)    -- 9
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §16  SWITCH / CASE / OTHERWISE / ENDSWITCH
-- ─────────────────────────────────────────────────────────────────

octave!
  day = "Mon";
  switch day
    case "Mon"
      disp("Monday")
    case "Fri"
      disp("Friday")
    otherwise
      disp("Other")
  endswitch
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §17  TRY / CATCH / ENDTRY
-- ─────────────────────────────────────────────────────────────────

octave!
  try
    disp(undefined_xyz)
  catch e
    disp("caught an error")
  endtry
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §18  FUNCTION DEFINITION & CALL
-- ─────────────────────────────────────────────────────────────────

octave!
  function y = square(x)
    y = x .^ 2.0;
  endfunction

  function z = add2(a, b)
    z = a + b;
  endfunction

  disp(square(7.0))       -- 49
  disp(add2(10.0, 32.0))  -- 42
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §19  RECURSIVE FUNCTION  (factorial)
-- ─────────────────────────────────────────────────────────────────

octave!
  function y = fact(n)
    if n <= 1.0
      y = 1.0;
    else
      y = n * fact(n - 1.0);
    endif
  endfunction

  disp(fact(6.0))    -- 720
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §20  GLOBAL & CLEAR
-- ─────────────────────────────────────────────────────────────────

octave!
  global G
  G = 99.0
  disp(G)
  clear G
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §21  MATRIX CONSTRUCTORS  (builtins)
-- ─────────────────────────────────────────────────────────────────

octave!
  disp(zeros(2.0, 3.0))
  disp(ones(3.0))
  disp(eye(3.0))
  disp(linspace(0.0, 1.0, 5.0))
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §22  MATH BUILTINS
-- ─────────────────────────────────────────────────────────────────

octave!
  disp(sqrt(2.0))
  disp(abs(-5.0))
  disp(exp(1.0))
  disp(log(exp(1.0)))
  disp(floor(3.7))
  disp(ceil(3.2))
  disp(round(3.5))
  disp(sin(0.0))
  disp(cos(0.0))
  disp(mod(17.0, 5.0))
  disp(max([3.0, 1.0, 5.0]))
  disp(min([3.0, 1.0, 5.0]))
  disp(sum([1.0, 2.0, 3.0, 4.0, 5.0]))
  disp(prod([1.0, 2.0, 3.0, 4.0, 5.0]))
  disp(mean([1.0, 2.0, 3.0, 4.0, 5.0]))
  disp(norm([3.0, 4.0]))
  disp(dot([1.0, 2.0], [3.0, 4.0]))
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §23  STRING BUILTINS
-- ─────────────────────────────────────────────────────────────────

octave!
  disp(strcat("foo", "bar"))
  disp(strcmp("a", "a"))
  disp(upper("hello"))
  disp(lower("WORLD"))
  disp(num2str(3.14))
  disp(str2double("2.718"))
  disp(strtrim("  hi  "))
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §24  TYPE QUERIES & SHAPE
-- ─────────────────────────────────────────────────────────────────

-- Note: class(...) is not in the DSL — "class" is a Lean keyword.
octave!
  disp(isnumeric(42.0))
  disp(ischar("x"))
  disp(isempty([]))
  disp(numel([1.0, 2.0, 3.0]))
  disp(size([[1.0, 2.0], [3.0, 4.0]]))
  disp(rows([[1.0, 2.0], [3.0, 4.0]]))
  disp(columns([[1.0, 2.0], [3.0, 4.0]]))
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §25  RESHAPE / HORZCAT / VERTCAT
-- ─────────────────────────────────────────────────────────────────

octave!
  v = 1:6;
  M = reshape(v, 2.0, 3.0)
  A = [[1.0, 2.0], [3.0, 4.0]];
  B = [[5.0, 6.0], [7.0, 8.0]];
  disp(horzcat(A, B))
  disp(vertcat(A, B))
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §26  PUTTING IT ALL TOGETHER — Newton's method
-- ─────────────────────────────────────────────────────────────────

octave!
  function x = newton_sqrt(n, tol)
    x = n / 2.0;
    while abs(x * x - n) > tol
      x = x - (x * x - n) / (2.0 * x);
    endwhile
  endfunction

  disp(newton_sqrt(2.0,  1e-10))   -- ≈ 1.4142135624
  disp(newton_sqrt(9.0,  1e-10))   -- ≈ 3.0
  disp(newton_sqrt(16.0, 1e-10))   -- ≈ 4.0
octave_end

-- ─────────────────────────────────────────────────────────────────
-- §27  PROOF INTEROP — expose AST for BigStep / PureEval proofs
-- ─────────────────────────────────────────────────────────────────

-- `octave_stmts! name ... octave_end` gives you the program as a named
-- `Array OctiveLean.Stmt` definition that you can reason about in Lean.

octave_stmts! myProg
  x = 0.0;
  for k = 1:3
    x = x + k;
  endfor
octave_end

-- myProg is now a Lean definition you can use in proofs:
#check (myProg : Array OctiveLean.Stmt)

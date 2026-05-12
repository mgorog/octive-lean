
function f = fact_custom(n)
  % computes n! recursivly
  if n>0
      f = n*fact_custom(n-1)
  else
      f = 1
  end
end

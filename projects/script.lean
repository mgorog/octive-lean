import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `script.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
(0==1)
0==0
a = 3.2; b = -2.1;
!(a == b)
xor((a!=3),(b<0))

pause
"Rounding up or down"
ceil(a)
floor(a)
ceil(b)
floor(b)

"hit return to continue"
pause
"finding max (or min)"
[m,i]=max([1,-3,4,40,34,29])

rand(2,2)
randn(2,2)

"hit return to continue"
pause
"working with strings"

f="first"
l="last"
m="middle"

strcmp(f,l)

ll = strrep(l, "a", "i")

abs(f)

name = [f, " ", m(1), ".", l]
PI=num2str(pi)
PI(2)
PI(2)=[];
PI
PI(5)

"That's all folks"

"List operators"
a=[1, 2, 3, 4]
b=[3, 5, 7, 9]

a+b
2*a+b
a.*b
a./b
a.^2
"Comment out the line giving theerror and rerun the scrippt"
-- a*b
a*b'

A=[1 2
3 4]
B=[3 0
1 -1]

A - B
A.*B
A./B
A.^B

A*B
linsolve(A, B
A/B

max(A)
sin(A)
abs(B)
log10(A)
exp(B)

"hit return to continue"
pause
"Making Special Arrays"

ones([2,3])
zeros(size(A))
rand(2,2)
eye(3)

"hit return to continue"
pause
"Logical statments"
}

function m=slope(x1,y1,x2,y2)
% Computes the slope from points (x1, y1), (x2, y2)
% where each input variable is
% a single number or a list of numbers the same length as the others.
% If two points are the same m = NaN;
% If only the first coordinates are the same m = Inf.
% Alternate Calling Forms:
%  2 Arguments:  m = slope(x1,y1)
%     where each row of x1 and y1
%     contains both coordinates of a point.
%     Both x1 and y1 must be n by 2 in this case.
%  No Arguments: m = slope
%     the function first checks for global inputs X1, Y1, X2, Y2
%     and calls m = slope(X1, Y1, X2, Y2)
%     or calls  m = slope(X1, Y1) if X1 has 2 columns
%     or calls m = slope(P,Q) if either X1 or Y1 is empty.

if nargin == 4
    m = (y2 - y1)./(x2 - x1);
elseif nargin == 2
    m = slope(x1(:,1),x1(:,2),y1(:,1),y1(:,2));
elseif nargin == 0
    global X1 Y1 X2 Y2
    sizeX1 = size(X1);
    if isempty(X1)|isempty(X2)
        global P Q
        m = slope(P,Q);
    elseif sizeX1(2) == 2
        m = slope(X1, Y1);
    else
        m = slope(X1, Y1, X2, Y2);
    end
end

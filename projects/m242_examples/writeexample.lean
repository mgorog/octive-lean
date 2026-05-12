import OctiveLean
open OctiveLean.DSL

/-! Auto-generated from `writeexample.m` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {
-- Sample Script for Data Writing

-- Data Structure Initialization

student(1).Name = "Happy Jack";
student(2).Name = "Sad Sam";
student(3).Name = "Whistling Willy";

student(1).ID = 1111;
student(2).ID = 2222;
student(3).ID = 3333;

-- Writing Student , ID table

fid1 = fopen("class.txt","w+");

n = length(student);

for ns = 1:n
    fprintf(fid1,"%20s",student(ns).Name);
    fprintf(fid1,"%6.0f\\n",student(ns).ID);
end

fclose(fid1);


-- Writing a Ledger

fid2 = fopen("ledger.txt","w+");

-- creating the expense sheet

n = 8;
m=5;
A = round(10000*rand(n,m))/100;

-- writing the expense sheet
for i = 1:n
    for j = 1:m
      fprintf(fid2,"$%6.2f,   ",A(i,j));
    end
    fprintf(fid2,"\\n");
end

fclose(fid2);
}

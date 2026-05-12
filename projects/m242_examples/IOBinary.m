% This script illustrates writing and reading binary files

% Create Data
A=[1,2,3,4,0,1.34];
word='Hello';
% Open a file for writing
[fn,pn]=uiputfile('*.bin','Pick name');
fidb=fopen([pn,fn],'w');
% Write the Array of Double Numbers
numA=fwrite(fidb,A,'double')
% Write the Word
numword=fwrite(fidb,word,'char')

errorcloseflag=fclose(fidb)

% Re-Opening the File

fidb2=fopen([pn,fn],'r');

% Read numbers back in in 2 rows, 3 columns

[A2, counta]=fread(fidb2,[2,3], 'double')

% Read Word back in

[word2,countw]=fread(fidb2,[5],'char')

% Converting to usual form

word2=setstr(word2')







% interactive_explainer.m
% This is now a FUNCTION file (starts with 'function')
% Run it by typing: interactive_explainer
%
% Why the change?
% Previous versions were scripts with local functions at the end.
% Some Octave versions/configurations have issues parsing local functions in scripts
% (warning about name mismatch + functions sometimes not recognized).
%
% Solution: Make the whole explainer a proper function (name matches filename).
% The helper functions are now SUBFUNCTIONS (placed after the main end).
% This is fully supported, no warnings, and functions are reliably available.
%
% Bonus: Variable "Initials" is explicitly placed in the base workspace
% using assignin() so you can access it after running (type Initials).

function interactive_explainer()

clc;
clear functions;  % Clear any old definitions

disp('=================================================================');
disp('    Welcome to the Interactive Octave Homework Explainer!    ');
disp('=================================================================');
disp('This script guides you through all three problems.');
disp('Press Enter to move forward at each pause.');
disp('=================================================================');

input('\nPress Enter to begin with Problem 1...');

% =================================================================
% Problem 1: Capitalized Initials
% =================================================================
disp('\n\n=== Problem 1: Capitalized Initials ======================');
disp('Requirements:');
disp('- Prompt for full name');
disp('- Display capitalized initials with dots');
disp('- Leave variable "Initials" in base workspace');

disp('\nCode that will run:');
code1 = {
'full_name = input(''Enter your full name: '', ''s'');'
'full_name = strtrim(full_name);'
'words = strsplit(full_name);'
'if isempty(words)'
'    Initials = '''';'
'else'
'    Initials = upper(words{1}(1));'
'    for i = 2:length(words)'
'        word = words{i};'
'        if ~isempty(word) && length(word) >= 1 && isletter(word(1))'
'            Initials = [Initials ''.'' upper(word(1))];'
'        end'
'    end'
'end'
'disp([''Your capitalized initials: '' Initials]);'
'assignin(''base'', ''Initials'', Initials);  % Make it visible in base workspace'
};
for k = 1:length(code1); disp(['   ' code1{k}]); end

input('\nPress Enter to run Problem 1...');

full_name = input('Enter your full name (with middle initial): ', 's');
full_name = strtrim(full_name);
words = strsplit(full_name);
if isempty(words)
    Initials = '';
else
    Initials = upper(words{1}(1));
    for i = 2:length(words)
        word = words{i};
        if ~isempty(word) && length(word) >= 1 && isletter(word(1))
            Initials = [Initials '.' upper(word(1))];
        end
    end
end
disp(['Your capitalized initials: ' Initials]);
disp('→ "Initials" is now in your base workspace (type Initials to see it).');
assignin('base', 'Initials', Initials);  % Ensure it appears in base workspace

input('\nPress Enter for Problem 2...');

% =================================================================
% Problem 2: Pig Latin Function
% =================================================================
disp('\n\n=== Problem 2: Pig Latin Function =========================');
disp('Requirements:');
disp('- Function with one input (word) and one output');
disp('- Preserve capitalization');
disp('- Ready for sentence translation');

disp('\nExact subfunction source (defined below):');
code2 = {
'function pigword = pig_latin(english_word)'
'    if isempty(english_word)'
'        pigword = ''''; return;'
'    end'
'    was_capitalized = isletter(english_word(1)) && isupper(english_word(1));'
'    word = lower(english_word);'
'    vowels = ''aeiou'';'
'    if any(word(1) == vowels)'
'        pig_lower = [word ''way''];'
'    else'
'        vowel_pos = find(ismember(word, vowels), 1, ''first'');'
'        if isempty(vowel_pos)'
'            pig_lower = [word ''ay''];'
'        else'
'            consonants = word(1:vowel_pos-1);'
'            rest = word(vowel_pos:end);'
'            pig_lower = [rest consonants ''ay''];'
'        end'
'    end'
'    pigword = pig_lower;'
'    if was_capitalized && ~isempty(pigword)'
'        pigword(1) = upper(pigword(1));'
'    end'
'end'
};
for k = 1:length(code2); disp(['   ' code2{k}]); end

input('\nPress Enter to test the function...');

disp('Testing single words...');
word1 = input('Enter a word: ', 's');
result1 = pig_latin(word1);
disp(['Pig Latin: ' result1]);

word2 = input('Enter a capitalized word (e.g., Bruce): ', 's');
result2 = pig_latin(word2);
disp(['Pig Latin: ' result2]);

disp('\nFull sentence demo:');
sentence = input('Enter a short sentence: ', 's');
words = strsplit(sentence);
pig_words = cellfun(@pig_latin, words, 'UniformOutput', false);
pig_sentence = strjoin(pig_words, ' ');
disp(['Pig Latin sentence: ' pig_sentence]);

input('\nPress Enter for Problem 3...');

% =================================================================
% Problem 3: Rectangle Printer
% =================================================================
disp('\n\n=== Problem 3: Rectangle Printer ===========================');
disp('Requirements:');
disp('- Function takes length (rows) and width (columns)');
disp('- Border *, interior .');
disp('- Cap width at 10');

disp('\nExact subfunction source (defined below):');
code3 = {
'function print_rectangle(length, width)'
'    if width > 10'
'        disp(''Width exceeds 10; capping at 10.'');'
'        width = 10;'
'    end'
'    if length < 1 || width < 1'
'        disp(''Dimensions must be positive integers.''); return;'
'    end'
'    border = ''*''; interior = ''.'';'
'    for row = 1:length'
'        if row == 1 || row == length'
'            line = repmat(border, 1, width);'
'        else'
'            if width <= 2'
'                line = repmat(border, 1, width);'
'            else'
'                line = [border repmat(interior, 1, width-2) border];'
'            end'
'        end'
'        disp(line);'
'    end'
'end'
};
for k = 1:length(code3); disp(['   ' code3{k}]); end

input('\nPress Enter to draw a rectangle...');

len = input('Enter length (rows): ');
wid = input('Enter width (columns): ');
print_rectangle(len, wid);

disp('\n=== All done! Thank you for completing the walkthrough. ===');

end  % End of main function interactive_explainer

% =================================================================
% Subfunctions (only visible inside this file)
% =================================================================

function pigword = pig_latin(english_word)
    if isempty(english_word)
        pigword = ''; return;
    end
    was_capitalized = isletter(english_word(1)) && isupper(english_word(1));
    word = lower(english_word);
    vowels = 'aeiou';
    if any(word(1) == vowels)
        pig_lower = [word 'way'];
    else
        vowel_pos = find(ismember(word, vowels), 1, 'first');
        if isempty(vowel_pos)
            pig_lower = [word 'ay'];
        else
            consonants = word(1:vowel_pos-1);
            rest = word(vowel_pos:end);
            pig_lower = [rest consonants 'ay'];
        end
    end
    pigword = pig_lower;
    if was_capitalized && ~isempty(pigword)
        pigword(1) = upper(pigword(1));
    end
end

function print_rectangle(length, width)
    if width > 10
        disp('Width exceeds 10; capping at 10.');
        width = 10;
    end
    if length < 1 || width < 1
        disp('Dimensions must be positive integers.');
        return;
    end
    border = '*'; interior = '.';
    for row = 1:length
        if row == 1 || row == length
            line = repmat(border, 1, width);
        else
            if width <= 2
                line = repmat(border, 1, width);
            else
                line = [border repmat(interior, 1, width-2) border];
            end
        end
        disp(line);
    end
end

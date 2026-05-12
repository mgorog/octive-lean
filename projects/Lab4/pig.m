
% pig.m
% This function translates a single English word into Pig Latin.
% Rules:
%   - If the word starts with a vowel, add "way" at the end.
%   - If the word starts with one or more consonants, move them to the end and add "ay".
%   - Capitalization of the first letter is preserved.
%
% Input(s):
%   english_word   string (single word)
%
% Output(s):
%   pigword        string containing the Pig Latin translation
%
% Tested sample command line calls and outputs:
% >> pword1 = pig('hello')
% pword1 = ellohay
%
% >> pword2 = pig('Bruce')
% pword2 = Ucebray
%
% Date of creation: February 20, 2026
% Programmer's name: Maximus

function pigword = pig(english_word)
    if isempty(english_word)
        pigword = ''; 
        return;
    end
    
    % Remember if the original word started with a capital letter
    was_capitalized = isletter(english_word(1)) && isupper(english_word(1));
    
    % Work with lowercase version
    word = lower(english_word);
    vowels = 'aeiou';
    
    if any(word(1) == vowels)
        pig_lower = [word 'way'];
    else
        % Find position of first vowel
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
    
    % Restore original capitalization
    if was_capitalized && ~isempty(pigword)
        pigword(1) = upper(pigword(1));
    end
end

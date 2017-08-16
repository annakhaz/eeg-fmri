
function [stsess, word] = readStudyList(thePath,listName)
% Read the contents of the study and test lists, and store them in the
% return variables.

cd(thePath.stimlists);
raw = read_table([listName '.txt']);  % read the study list into some structs


stsess          = 	raw.col1	;
word            = 	raw.col2	;

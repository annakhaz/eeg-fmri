
function [studysess, word] = readTestList(thePath,listName)
% Read the contents of the test lists, and store them in the
% return variables.

cd(thePath.stimlists);
raw = read_table([listName '.txt']);  % read the study list into some structs

studysess	=	raw.col1	;
word = raw.col2;
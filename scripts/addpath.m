
% MMT script
% This script loads the paths for the experiment, and creates
% the variable thePath in the workspace.

cd('../');
pwd
thePath.start = pwd;
cd('scripts/')

[pathstr,curr_dir] = fileparts(pwd); % AK: removed ,ext,versn to run on laptop
if ~strcmp(curr_dir,'scripts')
    fprintf(['You must start the experiment from the MMT_eeg/scripts directory. Go there and try again.\n']);
else
    thePath.scripts = fullfile(thePath.start, 'scripts');
    thePath.util = fullfile(thePath.scripts, 'util');
    thePath.stim = fullfile(thePath.start, 'stim');
    thePath.data = fullfile(thePath.start, 'data');
    thePath.stimlists = fullfile(thePath.start, 'stimlists');
    % add more dirs above

    % Add relevant paths for this experiment
    names = fieldnames(thePath);
    for f = 1:length(names)
        eval(['addpath(thePath.' names{f} ')']);
        fprintf(['added ' names{f} '\n']);
    end
    cd(thePath.scripts);
end

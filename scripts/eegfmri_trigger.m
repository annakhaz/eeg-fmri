function theData = MMT_eegfmri_study(thePath, sNum)

% Example use:
%  theData = MMT_eeg_study(thePath,'001')
% written by Melina Uncapher 4/21/08, 
% adapted from fMRI to EEG by Anna Khazenzon 7/23/15
% combined fMRI-EEG, Anna Khazenzon 8/5/16

%workaround for using retina
Screen('Preference', 'SkipSyncTests', 1);

while 1
    scanner = input('fmri [1], eeg [2], eeg-fmri [3]? ');
    % Set input device (keyboard or buttonbox)
        d = getBoxNumber;  % buttonbox
        S.kbNum = getKeyboardNumber_Curtis;
end

%% Input subject info:
sName = input('Enter subject initials: ','s');
sName = upper(sName);
sSess = input('Enter session number: ');
listName = ['feMMT',sNum,'_study', num2str(sSess)];
disp(listName);

%% Initialize screen:

screenNumber = 0;
screenColor = 0;
textColor = 255;
fixColor = [0 206 209];
[Window, myRect] = Screen(screenNumber, 'OpenWindow', screenColor, [], 32);
Screen('TextSize', Window, 36);
Screen('TextFont', Window, 'Times');

blinkColor = [255 128 0];

HideCursor;

    
%% create objects
% rects in which to place stim 
rectHeight(1) = 150;
rectWidth(1) = 150;

% flashing rect for blinks
blinkRect = round([Rect(3)/2-(rectWidth(1)+40), Rect(4)/2-(rectHeight(1)+40), Rect(3)/2+(rectWidth(1)+40), Rect(4)/2+(rectHeight(1)+40)]);

%% Load images

% Print a loading screen
Screen('Flip',Window);

% Read stimlist to load stims
[stsess, word] = MMT_readStudyList(thePath,listName); 
cd(thePath.stim);

% Determine number of trials in block
nTrials = length(word);

% Now load the  images, make the textures, and store the texture pointers in an array
for n = 1:nTrials
    StSess          = stsess(n,:);
    Word            = word(n,:);                            % word

end

% fill theData struct with (redundant) data from stimlist to combine with
% response data
trialcount = 0;
theData.sNum = sNum;
theData.sSess = sSess;
theData.stsess = stsess(1:nTrials,:);
theData.word = word(1:nTrials,:);



% preallocate the actual data cells
for preall = 1:nTrials
        theData.onset(preall) = 0;
        theData.resp{preall} = 'noanswer';
        theData.respRT(preall) = 0;  
        theData.nullTime(preall) = 0;
end

%% set trial timing
leadinTime = 1.0; % lead in time if scanning(to allow tissue equilibration at scanner)
leadoutTime = 10.0;
prestimTime = 1.0;
stimTime = 0.3;         % stim duration
respTime = 3.7; % max of 4s, will be variable
postRespTime = 0; % transition to blink 300ms after response
blinkTime = 2.0;
blinkRate = 0.5; % blink once every half-second
nBlinks = blinkTime/blinkRate;

ITIs =randsample([4,6], nTrials, true);

%% start the scan

DrawFormattedText(Window, 'Get ready!\nExperimenter, press g to begin','center','center',S.textColor);
Screen('Flip',Window);

tic
goTime = 0;

%% start timing/trigger

    if scanner==3 % TRIGGER
        while 1
            getKey_old('g',S.kbNum);
            [status, startTime] = StartScan_eprime; % startTime corresponds to GetSecs in startScan
            fprintf('Status = %d\n',status);
            
            if status == 0  % successful trigger otherwise try again
                break
            else
                Screen(S.Window,'FillRect', S.screenColor);	% Blank Screen
                Screen(S.Window,'Flip');
                message = 'Trigger failed. \n Press g to try again.';
                DrawFormattedText(S.Window,message,'center','center',S.textColor);
                Screen(S.Window,'Flip');
            end
        end

        goTime = goTime + leadinTime;
        DrawFormattedText(Window,'+','center','center',S.fixColor);
        Screen(S.Window,'Flip');
        recordKeys(startTime,goTime,d);  % not collecting keys, just a delay -- display 10 sec of "lead in" fixation before beginning

    elseif scanner == 4 % if hooked up to the EEG Netstation
        MU3getKey('g',S.kbNum);
        % start timing/trigger
        NetStation('Connect', '10.0.0.42'); %check this IP with the netstation
        WaitSecs(1);
        NetStation('Synchronize', 10);
        WaitSecs(1);
        NetStation('StartRecording');
        startTime = GetSecs; % for EEG, set this as the start time, all the onsets will be relative to this!
        goTime = goTime + leadinTime;
        DrawFormattedText(Window,'+','center','center',S.fixColor);
        Screen(S.Window,'Flip');
        NetStation('Synchronize', 10);
        NetStation('Event', 'CHK', GetSecs + 5);
        recordKeys(startTime,goTime,d);
    
    else % practice, so don't wait for trigger
        if scanner == 1         % on laptop
            MU3getKey('g',d);
        elseif scanner == 2         % in scanner
            MU3getKey('g',S.kbNum);
        end
        
        startTime = GetSecs;
        goTime = goTime + 1;  %display 1 sec of "lead in" fixation before beginning
        DrawFormattedText(Window,'+','center','center',S.fixColor);
        Screen(S.Window,'Flip');
        recordKeys(startTime,goTime,d);  % not collecting keys, just a delay -- display 4 sec of "lead in" fixation before beginning
        
    end

%% trial loop
n_noresp = 0;

for trial = 1:nTrials
    if n_noresp == 3 && trial == 4
        noresp_msg = true;
        break;
    else
        noresp_msg = false;
    end
    trialcount = trialcount + 1;
    theData.onset(trial) = GetSecs - startTime;
    ITI = ITIs(trial);%/1000;
    
%% ITI
    goTime = goTime + ITI;
    DrawFormattedText(Window, '+','center','center', S.fixColor);           
    Screen('Flip',Window); 
    
    if (scanner == 4)
        NetStation('Synchronize', 10);
        NetStation('Event', 'PRES', GetSecs + (ITI - prestimTime));
    end
    recordKeys(startTime,goTime,d);
    
%% STIM 
    goTime = goTime + stimTime;
           
    DrawFormattedText(Window, word{trial},'center','center',255);

        Screen('Flip',Window);                                          
        [keys1 RT1] = recordKeys(startTime,goTime,d);
        if RT1 > 0
            if (scanner == 4)
                NetStation('Synchronize', 10);
                NetStation('Event', 'RESP');
            end
        end   
%% RESPONSE WINDOW
        DrawFormattedText(Window, '+','center','center', S.fixColor);           
        Screen('Flip',Window); 
        
    if RT1 > 0
        keys2 = 'noresponse';
        RT2 = 0;
    else
        goTime = goTime + respTime;
        [keys2, RT2] = recordKeys(startTime,goTime,d);
        if RT2 ~= 0
            if (scanner == 4)
                NetStation('Synchronize', 10);
                NetStation('Event', 'RESP');
            end
            goTime = goTime - (respTime - RT2);
        else % if no response
            goTime = goTime + respTime;
        end
        
    end                   
    
    %Put keypress and RT in theData struct...
    if (RT1 > 0) && (RT2 == 0)                                               %if responded during stim duration
        theData.resp{trial} = keys1(1);
        theData.respRT(trial) = RT1(1);
    elseif (RT2 > 0) && (RT1 == 0)                                           %if responded during post-stim fixation
        theData.resp{trial} = keys2(1);
        theData.respRT(trial) = stimTime+RT2(1);
    elseif (RT1 > 0) && (RT2 > 0)                                            %if responded during both periods
        theData.resp{trial} = [keys1(1) keys2(1)];
        theData.respRT(trial) = 0; % AK: no RT if responded twice??
    elseif (RT1 == 0) && (RT2 == 0)
        theData.resp{trial} = 'noresponse';
        theData.respRT(trial) = 0;
        n_noresp = n_noresp + 1;
    else
        theData.resp{trial} = 'weirdness';
        theData.respRT(trial) = 0;
    end
        %output resp info to the command line...
        disp(['trial: ' num2str(trial)]);
        disp(['response: ' theData.resp{trial}]);
        disp(['RT: ' num2str(theData.respRT(trial))]);
        disp(['ITI: ' num2str(ITI)]);
        
 if (RT2 > 0) || (RT1 > 0)
     goTime = goTime + postRespTime;
     recordKeys(startTime,goTime,d);
 end
        
%% BLINK   
    
    if scanner == 4
            NetStation('Synchronize', 10);
            NetStation('Event', 'BLNK');       
    end

  
        goTime = goTime + blinkTime - 0.2;
        Screen('FillRect', Window, S.screenColor);
        DrawFormattedText(Window, '+','center','center', S.fixColor);
        DrawFormattedText(Window, '[BLINK]', 'center', 250, S.blinkColor);
        Screen('Flip', Window);
        recordKeys(startTime, goTime, d);
       
        goTime = goTime + 0.2;
        Screen('FillRect', Window, S.screenColor);  
        Screen('Flip', Window);

        recordKeys(startTime, goTime, d);
                
end
toc
beep


%% calculate summary stats, save data, clean up


fprintf(['\nExpected time: ' num2str(goTime)]);
fprintf(['\nActual time: ' num2str(GetSecs-startTime)]);

fprintf(['\nNumber of omitted responses: ' num2str(Noresp)]);

% save output file
cd(thePath.data);

%make Subj-specific directory for data
SubjDir = ['s' num2str(sNum)]
if ~exist(SubjDir,'dir'); mkdir(SubjDir); end
cd(SubjDir);


matName = [listName 'out.mat'];
save(matName);

saveName = [listName '_' sName '_out.txt'];

fid = fopen(saveName, 'wt');
fprintf(fid, ('subjNum\tsessInput\tstudySess\tonset\tword\tresp\tRT\tITI\n'));
for n = 1:trialcount
    fprintf(fid, '%s\t%f\t%f\t%f\t%s\t%s\t%f\t%f\n',...
        theData.sNum,theData.sSess,theData.stsess(n),theData.onset(n),theData.word{n}, ...
        theData.resp{n}, theData.respRT(n), ITIs(n));
        
end

Screen('FillRect',Window,0);                                        
Screen('Flip',Window);                                              
pause(2);                                                           
% Print a goodbye screen
DrawFormattedText(Window, 'End of this session!','center','center',255); 
Screen('Flip',Window);

pause(2);                                                              % wait for any keypress to close the screen
clear screen
ShowCursor;

if scanner == 4 % if EEG
    NetStation('StopRecording');
end
    
cd(thePath.start);                                                  %return to main directory

if noresp_msg
    disp('NOT RESPONDING')
end




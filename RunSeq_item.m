function RunSeq_item(varargin)
%% SETUP

commandwindow; % bring focus to command window.

script_path=which('RunSeq_item.m');
script_dirct=fileparts(script_path);
PTB.script_dirct=script_dirct;
base_dir=fileparts(script_dirct);
cd(script_dirct);

%% Setup GUI &| Parsing inputs

DefAns = struct([]);
DefAns(1).SubID = 701;
d = dir([base_dir filesep 'lists' filesep '*.mat']);
files = strcat([base_dir filesep 'lists' filesep],{d(~[d.isdir]).name});
DefAns.counterB_file = files{end};
DefAns.scan = 'No';
DefAns.phase='Demo';
DefAns.block_start = 1;

if nargin==0
    Title = 'Inputs for Running Sequence';
    
    Options.Resize = 'on';
    Options.Interpreter = 'tex';
    Options.CancelButton = 'on';
    Options.AlignControls = 'on';
    
    Prompt = {};
    Formats = {};
    
    Prompt(1,:) = {'Please enter the correct information for running sequence task',[]};
    Formats(1,1).type = 'text';
    Formats(1,1).size = [-1 0];
    Formats(1,1).span = [1 2]; % item is 1 field x 4 fields
    
    Prompt(2,:) = {'Subject Number', 'SubID'};
    Formats(2,1).type = 'edit';
    Formats(2,1).format = 'integer';
    Formats(2,1).unitsloc = 'bottomleft';
    Formats(2,1).limits = [700 799];
    Formats(2,1).size = 200; % automatically assign the height
    
    Prompt(end+1,:) = {'Counter Balancing file','counterB_file'};
    Formats(3,1).type = 'edit';
    Formats(3,1).format = 'file';
    Formats(3,1).items = {'*.mat*';'*.m';'*.*'};
    Formats(3,1).limits = [0 1]; % single file get
    Formats(3,1).size = [-1 0];
    Formats(3,1).span = [1 2];  % item is 1 field x 3 fields
    
    Prompt(end+1,:) = {'In Scanner?','scan'};
    Formats(4,:).type = 'list';
    Formats(4,:).style = 'radiobutton';
    Formats(4,:).format = 'text';
    Formats(4,:).items = {'Yes' 'No' 'Yes - W/O Trigger'};
    Formats(4,:).span = [1 2];
    
    Prompt(end+1,:) = {'Phase','phase'};
    Formats(5,1).type = 'list';
    Formats(5,1).style = 'popupmenu';
    Formats(5,1).format = 'text';
    Formats(5,1).size = 200;
    Formats(5,1).items = {'Demo','PreScan','Scan Demo','N-Back','Scan','Post-scan'};
    
    Prompt(end+1,:) = {'Starting Block','block_start'};
    Formats(5,2).type = 'edit';
    Formats(5,2).format = 'integer';
    Formats(5,2).limits = [1 3];%CHANGE FOR BLOCKS
    Formats(5,2).size = 200;
    Formats(5,2).unitsloc = 'bottomleft';
    
    [Settings,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
    move_on=false;
    
    while ~move_on
        if Cancelled
            error('runSeq:Setup','Setup prompt cancelled by user')
        end
        
        [~,file_name,~]=fileparts(Settings.counterB_file);
        file_username=file_name(1:3);
        
        if ~strcmp(file_username,num2str(Settings.SubID))
            runn=questdlg(sprintf('Warning, the subject ID number you entered (%d)\ndoes not match the ID number of the counterbalancing list selected (%s)\nHow would you like to proceed?',...
                Settings.SubID,file_username),'Warning','Re-enter info','Continue as is','Quit','Re-enter info');
            switch runn
                case 'Re-enter info'
                    [Settings,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
                case 'Quit'
                    Cancelled=true;
                case 'Continue as is'
                    move_on=true;
            end
        else
            move_on=true;
        end
    end
else
    p=inputParser;
    dfSettings=DefAns;
    dfPhase='Demo';
    vPhase={'Demo','PreScan','N-Back','Scan Demo','Scan','Post-scan'};
    ckPhase=@(x) any(validatestring(x,vPhase));
    dfScan='No';
    vScan={'Yes' 'No' 'Yes - W/O Trigger'};
    ckScan=@(x) any(validatestring(x,vScan));
    
    addParamValue(p,'settings',dfSettings,@isstruct);
    addParamValue(p,'phase',dfPhase,ckPhase);
    addParamValue(p,'scan',dfScan,ckScan);
    parse(p,varargin{:});
    
    Settings=p.Results.settings;
    if ~ismember('phase',p.UsingDefaults)
        Settings.phase{1}=p.Results.phase;
    end
    if ~ismember('scan',p.UsingDefaults)
        Settings.scan=p.Results.scan;
    end
end

counterlist=[];
load(Settings.counterB_file);

practice=struct;
load(strcat([base_dir filesep '/stims/practice.mat']));%loads a structure that contains all the info for practice trials
%%

%%%%%%%%%%%%%  BEGIN DARA'S CODE FOR QUERYING THE DEVICES
%%%%%%%%%%%%%
%numDevices=PsychHID('NumDevices');
devices=PsychHID('Devices');

% first find all keyboard devices
keydevs=[];
for d=1:length(devices)
    if strcmp(devices(d).usageName,'Keyboard')
        keydevs=[keydevs d];
    end
end
%keydevs;

% find bbox and trigger
inputDevName=cell(1,3);
for k=1:length(keydevs),
    %if findstr(devices(keydevs(k)).manufacturer,''),
    %if devices(keydevs(k)).productID==16385, % this is the ID of the old bbox at UCLA brain mapping center's Allegra scanner
    % BBOX
    if devices(keydevs(k)).vendorID==6171, % this is the ID of the
        %bbox at UCLA brain mapping center's Trio scanner
        inputDevice(1)=keydevs(k);
        inputDevName{1}='BBOX';
        fprintf('BBOX: device #%d: productID - %d\n',keydevs(k),devices(keydevs(k)).productID)
    elseif findstr(devices(keydevs(k)).manufacturer,'P.I. Engineering'),
        % TRIGGER
        inputDevice(2)=keydevs(k);
        inputDevName{2}='TRIGGER';
        fprintf('TRIGGER: device #%d: manuf - %s\n',keydevs(k),devices(keydevs(k)).manufacturer)
    elseif findstr(devices(keydevs(k)).manufacturer,'Apple'),
        % APPLE KEYBOARD
        inputDevice(3)=keydevs(k);
        inputDevName{3}='AppleKeyboard';
        fprintf('AppleKeyboard: device #%d: manuf - %s\n',keydevs(k),devices(keydevs(k)).manufacturer)
    elseif findstr(devices(keydevs(k)).product,'Apple Extended USB Keyboard'),
        % APPLE KEYBOARD - some reason the keyboard for the mac mini isnt
        % made by apple, so the above fails
        inputDevice(3)=keydevs(k);
        inputDevName{3}='AppleKeyboard';
        fprintf('AppleKeyboard: device #%d: manuf - %s\n',keydevs(k),devices(keydevs(k)).manufacturer)
    end
end
fprintf('\n');
%%%%%%%%%%%%%  END DARA'S CODE FOR QUERYING THE DEVICES %%%%%%%%%%%%%%%%%%

%% PROBLEM HERE!
switch Settings.scan
    case 'Yes'
        PTB.boxNum=inputDevice(1);%bbox
        PTB.kbNum=inputDevice(3);%keyboard
    case {'No','Yes - W/O Trigger'}
        %gets device numbers for subject responces
        PTB.boxNum=inputDevice(3);%keyboard
        PTB.kbNum=inputDevice(3);%keyboard
end
KbQueueCreate(PTB.boxNum);

%% Task timing parameters

PTB.trigger_char='5'; % for new trigger at BMC
Settings.num_learn_repeats=3;% Number of pre-exposures
Settings.learn_blocks=8;%Number of blocks to break pre-exposure intor
Settings.blocks=4;

%Times for prescan
preStart=2.0;
%Times for test
leadin=5.0;%two TRs,
bettime=2.0;
leadout=8.0;

readyforarrowsTime = .5;
arrowTime = 1.0; % the arrows during the ITI
postarrowTime = (2/3);
%readyfornexttrialTime = .5;

PTB.ITImin=2;
PTB.ITImax=6;

image_time=1.25;
fixation_time=.25;
ITI=.5;

%% Task screen parameters
PTB.screenNumber=0;
PTB.screenColor=220; %%grey
PTB.textColor=0;  %%black
%Screen('Preference', 'SkipSyncTests', 1);
PTB.old=Screen('Resolution', PTB.screenNumber, [], []);
switch Settings.phase{1}
    case {'Demo','PreScan','N-Back','Scan','Scan Demo'}
        Screen('Resolution', PTB.screenNumber, 800, 600);
end

res=Screen('Resolution', PTB.screenNumber, [], []);
PTB.textSize=round(res.width/60);
PTB.instructionSize=round(res.width/75);
PTB.wrap=round((res.width*1.5)/PTB.textSize);


[PTB.Window, PTB.myRect]= Screen(PTB.screenNumber, 'OpenWindow', PTB.screenColor, []);
Screen(PTB.Window,'FillRect', PTB.screenColor);
Screen(PTB.Window,'Flip');%starts blank screen
Screen('TextSize',PTB.Window,PTB.instructionSize);

switch Settings.phase{1}
    case {'Demo','PreScan','N-Back','Scan','Scan Demo'}
        HideCursor;
end
finishup=onCleanup(@() myCleanupFun(PTB));
commandwindow;
% Set params for W x H stimulus dimensions
stim_dim=[0 0 200 200];
stim_bg_dim=[0 0 400 400];
[PTB.xCenter, PTB.yCenter] = RectCenter(PTB.myRect);
PTB.xMax=PTB.myRect(3);PTB.yMax=PTB.myRect(4);
PTB.stim_rect=CenterRectOnPointd(stim_dim,PTB.xCenter,PTB.yCenter);
PTB.stim_bg_rect=CenterRectOnPointd(stim_bg_dim,PTB.xCenter,PTB.yCenter);

%% Image setup
cd([base_dir '/stims/'])

fileName = 'fix.jpg';
pic = imread(fileName);
PTB.fix = Screen(PTB.Window,'MakeTexture', pic);

fileName = 'R_arrow.jpg';
pic = imread(fileName);
PTB.R_arrow = Screen(PTB.Window,'MakeTexture', pic);

fileName = 'L_arrow.jpg';
pic = imread(fileName);
PTB.L_arrow = Screen(PTB.Window,'MakeTexture', pic);

for g=1:4
    fileName=['Probe' num2str(g) '.jpg'];
    pic = imread(fileName);
    Probe(g) = Screen(PTB.Window,'MakeTexture', pic);
end
probe_message{1}='How many items in the sequence are LARGER than the item that came before it?';
probe_message{2}='How many items in the sequence would be SEEN WITH the item that came before it?';
probe_message{3}='How many items in the sequence are made of the SAME MATERIAL as the item that came before it?';
probe_message{4}='How many items in the sequence are SMALLER than the item that came before it?';

fileName = 'continue.jpg';
pic = imread(fileName);
PTB.cont = Screen(PTB.Window,'MakeTexture', pic);

fileName = 'continue_grey.jpg';
pic = imread(fileName);
PTB.cont_grey = Screen(PTB.Window,'MakeTexture', pic);

target_names={'first.jpg','second.jpg','third.jpg','fourth.jpg'};
for g=1:length(target_names)
    pic = imread(target_names{g});
    PTB.target_img(g)=Screen(PTB.Window,'MakeTexture', pic);
end

for g=1:3
    fileName=['TestProbe' num2str(g) '.jpg'];
    pic = imread(fileName);
    PTB.button(g) = Screen(PTB.Window,'MakeTexture', pic);
end


%% DEMO
while strcmp(Settings.phase,'Demo')
    cd([base_dir '/stims/']);
    
    savefiletx=sprintf('%s/data/%d_Demo_data_%s_%s.txt',base_dir,Settings.SubID,date,datestr(now,13));
    
    fileID = fopen(savefiletx,'a');
    fprintf(fileID,'Sequence data -Demo- file for %d at %s \nTrial\tSequence Ref\tSequence Onset\tProbe Onset\tProbe_Resp\tProbe_RT\tCorrect\n',Settings.SubID,datestr(now));
    
    for n=1:length(practice.learn_trials) %pre-makes textures for practice
        holder=[];
        for m=1:length(practice.trial_info(practice.learn_trials(n)).pre.image_names)
            picname=practice.trial_info(practice.learn_trials(n)).pre.image_names{m};
            pic=imread(char(picname),'jpg');
            holder(m)=Screen(PTB.Window,'MakeTexture',pic);
        end
        practice.sequences{n}=holder;
        picname=practice.trial_info(practice.learn_trials(n)).pre.bg_name;
        pic=imread(char(picname),'jpg');
        practice.background(n)=Screen(PTB.Window,'MakeTexture',pic);
    end
    
    cd(script_dirct);
    
    theData=preAllocate(length(practice.learn_trials),'demo',false,[]);
    
    %intructions on screen
    message=sprintf(['In this experiment you will be making judgments about the relationships between items. '...
        'Each trial will present a series of images.  For each series you need to determine how many '...
        'of the items in that series meet a specified relationship with the item that preceded it. '...
        'For example, one relationship will be "larger", so that you need to determine how many items '...
        'in a series are larger that the item that preceded it.  If the sequence is house, pencil, dog, '...
        'bear, in that order, the number of larger images would be "2", as a dog is larger than a pencil, '...
        'and a bear is larger than a dog, but a pencil is not larger than a house. Other relationships will be:\n\n'...
        '"Would be seen with the previous item",\n'...
        '"Made of the same material/stuff as the previous item".\n\n'...
        'Do these relationships make sense to you?']);
    
    drawMessage_moveOn(PTB,message,'continue instructions')
    
    message=sprintf(['Each image will be on the screen for about a second, with a brief delay between each image. '...
        'After each series you will be prompted to enter how many times the relationship was met, ranging from 0 to 3.'...
        ' On the keyboard use ''1'' to indicate 0 and ''4'' to indicate 3. The probe will be on the screen for about 2 seconds,'...
        ' please try to respond in that time.\nFor many items whether the relationship has been met will be ambiguous.'...
        ' There is no one correct answer, just use your best judgment.\n\nWe will start with a quick practice run so that '...
        'you can see the format and pace of the task.']);
    drawMessage_moveOn(PTB,message,'begin')
    drawMessage_moveOn(PTB,probe_message{1},'begin')
    
    startTime = GetSecs;goTime = 0;goTime=goTime+preStart;%lead in time
    
    Screen(PTB.Window,'FillRect', PTB.screenColor);
    Screen(PTB.Window,'Flip');
    WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
    
    index=randperm(length(practice.learn_trials));%random order of practice presentaion
    
    for n=1:length(practice.learn_trials)
        
        theData.demo(n).onset.sequence=goTime;theData.demo(n).sequence_ref=index(n);
        
        fprintf(fileID,'%d\t%d\t%.3f\t',n,theData.demo(n).sequence_ref,goTime);
        
        goTime=draw_sequence(PTB, practice.sequences{index(n)}, practice.background(index(n)), startTime, goTime, image_time, fixation_time);
            close_textures(practice.sequences{index(n)});
        fprintf(fileID,'%.3f\t',goTime);
        
        % Probe
        theData.demo(n).onset.probe=goTime;KbQueueStart;
        goTime=goTime+bettime;kbgoTime=goTime+.45;
        
        Screen(PTB.Window, 'DrawTexture', Probe(1)); Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime);
        
        %ITI & Response collection
        goTime=goTime+ITI;Screen(PTB.Window,'FillRect', PTB.screenColor); Screen(PTB.Window,'Flip');%ITI, CHANGE IF NO BLANK SCREEN!!!
        
        WaitSecs('UntilTime',startTime+kbgoTime);%wait for extra response time
        KbQueueStop;[~, firstPress]=KbQueueCheck;
        
        theData=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,n,'demo');
        
        fprintf(fileID,'%s\t%.3f\t%d\n',theData.demo(n).resp.first,theData.demo(n).respRT.first);
        
        WaitSecs('UntilTime',startTime+goTime);%ITI over
    end
    
    goTime=goTime+2;
    Screen(PTB.Window,'FillRect', PTB.screenColor);
    Screen(PTB.Window,'Flip');
    WaitSecs('UntilTime',startTime+goTime);
    
    message='Do you have any questions about the task now that you have practiced it?';
    drawMessage_moveOn(PTB,message,'continue')
    
    savefile=sprintf('%s/data/%d_Demo_data_%s.mat',base_dir,Settings.SubID,date);
    save(savefile,'theData','counterlist','Settings');
    
    clear Screen;
    ShowCursor;
    runn=questdlg('The demo is complete, rerun?','Demo Complete','Rerun','Move on','Quit','Move on');
    switch runn
        case 'Rerun'
            RunSeq('settings',Settings,'phase','Demo');
        case 'Move on'
            RunSeq('settings',Settings,'phase','PreScan');
        case 'Quit'
            Settings.phase{1}='Quit';
    end
    
end

%%
switch(Settings.phase{1})
    %% PRE-EXPOSURE
    case 'PreScan'
        tic
        RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));%%Resets the randomization list, otherwise would call the same random list every time matlab restarts
        
        message='loading images...'; %screen says loading images if it takes a while to make all the textures
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        savefiletx=sprintf('%s/data/%d_PreExposed_data_%s_%s.txt',base_dir,Settings.SubID,date,datestr(now,13));
        
        fileID = fopen(savefiletx,'a');
        fprintf(fileID,'Sequence data -PreExposed- file for %d at %s \nBlock\tTrial\tTotal Trial\tSequence Ref\tSequence Onset\tProbe Onset\tProbe_Resp\tProbe_RT\tCorrect\n',Settings.SubID,datestr(now));
        
        
        cd([base_dir '/stims/']);
        for n=1:length(counterlist.learn_trials) %pre-makes textures for practice
            holder=[];
            for m=1:length(counterlist.trial_info(counterlist.learn_trials(n)).pre.image_names)
                picname=counterlist.trial_info(counterlist.learn_trials(n)).pre.image_names{m};
                pic=imread(char(picname),'jpg');
                holder(m)=Screen(PTB.Window,'MakeTexture',pic);
            end
            preexposure.sequences{n}=holder;
            picname=counterlist.trial_info(counterlist.learn_trials(n)).pre.bg_name;
            pic=imread(char(picname),'jpg');
            preexposure.background(n)=Screen(PTB.Window,'MakeTexture',pic);
        end
        cd(script_dirct);
        
        theData=preAllocate(length(counterlist.learn_trials)*Settings.num_learn_repeats,'preexposure',false,[]);
        
        %intructions on screen
        message=['This first phase of the experiment will broken into three blocks, each running for approximately 13'...
            ' minutes. Each block will ask about a different relationship, to which you will be prompted at the start '...
            'of each block. There will be a break in the middle of each block for you to rest and relax your mind. '...
            'Once you are ready to move onto the next block press ''b'' to continue.'];
        drawMessage_moveOn(PTB,message,'begin')
        
        goTime = 0;
                
        startTime = GetSecs;%starts everything from when 'b' is pressed
                
        Screen(PTB.Window,'FillRect', PTB.screenColor); Screen(PTB.Window,'Flip');
        
        for h=1:Settings.num_learn_repeats
            
            index=randperm(length(counterlist.learn_trials));%random order of practice presentaion
            
            delay_start=GetSecs;
            drawMessage_moveOn(PTB,probe_message{h},'begin')
            
            delay_end=GetSecs;
            delaytime=delay_end-delay_start;
            goTime=goTime+preStart+delaytime;%lead in time
            WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
            
            for n=1:length(counterlist.learn_trials)
                
                if n==length(counterlist.learn_trials)/2
                    delay_start=GetSecs;
                    message='Break \n Please take a minute to rest and relax';
                    drawMessage_moveOn(PTB,message,'continue')
                    
                    delay_end=GetSecs;
                    delaytime=delay_end-delay_start;
                    goTime=goTime+preStart+delaytime;
                end
                trial_index=((h-1)*length(counterlist.learn_trials))+n;
                
                theData.preexposure(trial_index).onset.sequence=goTime;
                theData.preexposure(trial_index).sequence_ref=index(n);
                
                fprintf(fileID,'%d\t%d\t%d\t%d\t%.3f\t',h,n,trial_index,theData.preexposure(trial_index).sequence_ref,goTime);
                
                goTime=draw_sequence(PTB, preexposure.sequences{index(n)}, preexposure.background(index(n)), startTime, goTime, image_time, fixation_time);
                
                fprintf(fileID,'%.3f\t',goTime);
                
                % Probe
                theData.preexposure(trial_index).onset.probe=goTime;
                KbQueueStart;
                goTime=goTime+bettime;
                kbgoTime=goTime+.45;
                
                Screen(PTB.Window, 'DrawTexture', Probe(h)); Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
                
                %ITI & Response collection
                goTime=goTime+ITI;
                
                Screen(PTB.Window,'FillRect', PTB.screenColor); Screen(PTB.Window,'Flip');%ITI, CHANGE IF NO BLANK SCREEN!!!
                
                WaitSecs('UntilTime',startTime+kbgoTime);%wait for extra response time
                KbQueueStop; %stop recording button responces
                [~, firstPress]=KbQueueCheck;
                
                theData=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,trial_index,'preexposure');
                             
                fprintf(fileID,'%s\t%.3f\n',theData.preexposure(trial_index).resp.first,theData.preexposure(trial_index).respRT.first);
                
                WaitSecs('UntilTime',startTime+goTime);%ITI over
            end
            
            if h ~= Settings.num_learn_repeats
                delay_start=GetSecs;
                message='Break \n Please take a minute to rest and relax';
                drawMessage_moveOn(PTB,message,'continue')
                
                delay_end=GetSecs;
                delaytime=delay_end-delay_start;
                goTime=goTime+delaytime;%lead in time
            end
            
        end
        
        goTime=goTime+leadout;
        Screen(PTB.Window,'FillRect', PTB.screenColor);%ITI, CHANGE IF NO BLANK SCREEN!!!
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime);
        
        savefile=sprintf('%s/data/%d_PreExposed_data_%s_final.mat',base_dir,Settings.SubID,date);
        save(savefile,'theData','counterlist','Settings');
        message='Congratulations, you have completed the this phase of the experiment.  \nThank you very much!';
        
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        pause(5);
        
        clear Screen;ShowCursor;
        runn=questdlg('The pre-scan is complete, move on?','Pre-scan Complete','Move on','Quit','Move on');
        switch runn
            case 'Move on'
                RunSeq('settings',Settings,'phase','Scan Demo');
            case 'Quit'
                Settings.phase{1}='Quit';
        end
        toc
        %% LEARNING TWO DEMO    
    case 'Scan Demo'
        message='loading images...'; %screen says loading images if it takes a while to make all the textures
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        practice.scan_order=randperm(length(practice.trial_info));
        
        cd([base_dir '/stims/']);
        for n=1:length(practice.trial_info) %pre-makes textures for practice
            holder=[];
            for m=1:length(practice.trial_info(practice.scan_order(n)).scan.image_names)
                picname=practice.trial_info(practice.scan_order(n)).scan.image_names{m};
                pic=imread(char(picname),'jpg');
                holder(m)=Screen(PTB.Window,'MakeTexture',pic);
            end
            practice.sequences{n}=holder;
            picname=practice.trial_info(practice.scan_order(n)).scan.bg_name;
            pic=imread(char(picname),'jpg');
            practice.background(n)=Screen(PTB.Window,'MakeTexture',pic);
        end
        for n=1:length(practice.pre_trials) %pre-makes textures for practice
            picname=practice.pre_trials(n).image;
            pic=imread(char(picname),'jpg');
            practice.pre_trials(n).texture=Screen(PTB.Window,'MakeTexture',pic);
        end
        cd(script_dirct);
        %intructions on screen
        message=['Now we will move onto the scanner portion of the experiment. There are two tasks that make up this phase. '...
            'In the first task you will see a series of images, each presented for one second. Your job is the press '...
            'the first button, ''1'', when an image is repeated (shown twice in a row). \n\n'...
            'The second task in this phase will be very similar to the '...
            'first phase you just completed. You will be again making judgments about the relationship between an image and the image that '...
            'preceded it. Only one relationship will be used: "Smaller than the previous item." One addition to this phase '...
            'of the experiment is that between each trial you will see a number of arrows. For each arrow indicate the '...
            'direction the arrow is pointing, ''1'' for left, ''2'' for right.  Any questions?\n\nAgain we will start '...
            'with a quick practice run of both tasks so that you can see the format and pace of the task.'];
        drawMessage_moveOn(PTB,message,'begin')
        
        theData=preAllocate(length(practice.pre_trials),'pre_demo',false,[]);
        
        goTime = 0;
        
        startTime = GetSecs;%starts everything from when triggered
        goTime=goTime+preStart;%lead in time
        
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
        
        for n=1:length(practice.pre_trials)
            theData.pre_demo(n).probe.goTime=goTime;
            KbQueueStart;
            goTime=goTime+.75;
            Screen(PTB.Window, 'DrawTexture',practice.pre_trials(n).texture,[],PTB.stim_rect);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
            %close_textures([practice.pre_trials(n).texture]);
            % Fixation
            goTime=goTime+.25;
            Screen(PTB.Window, 'DrawTexture', PTB.fix);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);KbQueueStop;[~, firstPress]=KbQueueCheck;            
            theData=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,n,'pre_demo');
        end
        
        goTime=goTime+3;
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime);
        message='Do you have any questions about the task now that you have practiced it?\n\n Now we will practice the other task';
        drawMessage_moveOn(PTB,message,'continue')
        
        drawMessage_moveOn(PTB,probe_message{end},'begin')

        theData=preAllocate(length(practice.scan_order),'scan_demo',true,4);
        goTime = 0;
        
        startTime = GetSecs;%starts everything from when triggered
        goTime=goTime+preStart;%lead in time
        
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
        
        index=randperm(length(practice.trial_info));
        for n=1:length(practice.trial_info)
            ISIs = ((PTB.ITImax-PTB.ITImin)*rand(1,(length(practice.trial_info)-1)))+PTB.ITImin;ISIs = (round(ISIs*1000))/1000;
            
            goTime=draw_sequence(PTB,practice.sequences{index(n)},practice.background(index(n)), startTime, goTime, image_time, fixation_time);
                close_textures(practice.sequences{index(n)});
            % Probe
            KbQueueStart;goTime=goTime+bettime;
            
            Screen(PTB.Window, 'DrawTexture', Probe(end));Screen(PTB.Window,'Flip');WaitSecs('UntilTime',startTime+goTime);
            
            %ITI & Response collection
            goTime=goTime+readyforarrowsTime;
            
            Screen(PTB.Window,'FillRect', PTB.screenColor);Screen(PTB.Window,'Flip');
            
            WaitSecs('UntilTime',startTime+goTime);KbQueueStop;[~, firstPress]=KbQueueCheck;
            
            theData=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,n,'scan_demo');
            
            if n~=length(practice.scan_order) %no arrows on last trial
                num_arrows=floor(ISIs(n))-1;iti_rem=ISIs(n)-num_arrows-.5;
                [theData,goTime]=arrows(num_arrows,PTB,theData,startTime,goTime,arrowTime,postarrowTime,n,'scan_demo');
                
                goTime=goTime+iti_rem;Screen(PTB.Window,'FillRect', PTB.screenColor);
                Screen(PTB.Window,'Flip');WaitSecs('UntilTime',startTime+goTime);
            end
        end
        
        message=sprintf(['Do you have any questions about the task now that you have practiced it?\n\n The first task will consist of one block '...
            'lasting about 6 minutes.  The second task will '...
            'be broken up into four blocks, each about 6 minutes long, with breaks to rest between.']);
        drawMessage_moveOn(PTB,message,'continue')
        
        clear Screen;ShowCursor;
        runn=questdlg('The scan demo is complete, move on?','Scan Demo Complete','Move on - w/o Trigger','Move on - w/ Trigger','Quit','Move on - w/o Trigger');
        switch runn
            case 'Move on - w/ Trigger'
                RunSeq('settings',Settings,'phase','N-Back','scan','Yes');
            case 'Move on - w/o Trigger'
                RunSeq('settings',Settings,'phase','N-Back');
            case 'Quit'
                Settings.phase{1}='Quit';
        end
    %%
    case 'N-Back'
        message='loading images...'; %screen says loading images if it takes a while to make all the textures
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        cd([base_dir '/stims/']);
        for n=1:length(counterlist.pre_trials) %pre-makes textures for practice
            picname=counterlist.pre_trials(n).image;
            pic=imread(char(picname),'jpg');
            counterlist.pre_trials(n).texture=Screen(PTB.Window,'MakeTexture',pic);
        end
        cd(script_dirct);
        %intructions on screen
        message=['You will see a series of images, each presented for one second. Your job is the press '...
            'the first button, ''1'', when an image is repeated (shown twice in a row). \n\n'...
            'Throughout this run a fixation cross will be shown for a couple seconds. '...
            'Please continue to pay attention during this time, as the images will come back on again quickly.'];
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        start_scan(Settings,PTB)
        
        theData=preAllocate(length(counterlist.pre_trials),'pre_scan',false,[]);
        
        goTime = 0;
        
        startTime = GetSecs;%starts everything from when triggered
        goTime=goTime+preStart;%lead in time
        
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
        
        for n=1:length(counterlist.pre_trials)
            theData.pre_scan(n).probe.goTime=goTime;
            KbQueueStart;
            goTime=goTime+.75;
            Screen(PTB.Window, 'DrawTexture',counterlist.pre_trials(n).texture,[],PTB.stim_rect);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
            %close_textures([counterlist.pre_trials(n).texture]);
            % Fixation
            goTime=goTime+.25;
            Screen(PTB.Window, 'DrawTexture', PTB.fix);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);KbQueueStop;[~, firstPress]=KbQueueCheck;            
            theData=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,n,'pre_scan');
        end
        
        goTime=goTime+leadout;
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime);
        message='Congratulations, you have completed this task.  \nThank you very much!';

        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
            
        pause(5);%wait 5 second before clearing screen
            
        savefile=sprintf('%s/data/%d_data_%s_preexpose.mat',base_dir,Settings.SubID,date);
        
        save(savefile,'theData','counterlist','Settings');
        
        clear Screen;ShowCursor;
        runn=questdlg('The N-Back is complete, move on?','N-Back Complete','Move on','Quit','Move on');
        switch runn
            case 'Move on'
                RunSeq('settings',Settings,'phase','Scan');
            case 'Quit'
                Settings.phase{1}='Quit';
        end
        
    %% LEARNING TWO    
    case 'Scan'
        
        message='loading images...'; %screen says loading images if it takes a while to make all the textures
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        if Settings.block_start==1
            savefiletx=sprintf('%s/data/%d_data_%s_%s.txt',base_dir,Settings.SubID,date,datestr(now,13));
        else
            savefiletx=sprintf('%s/data/%d_data_%s_startblock_%d_%s.txt',base_dir,Settings.SubID,date,Settings.block_start,datestr(now,13));
        end
        
        fileID = fopen(savefiletx,'a');
        fprintf(fileID,'Sequence data file for %d at %s starting with block %d\nBlock\tTrial\tTotal Trial\tSequence Ref\tSequence Onset\tProbe Onset\tProbe_Resp\tProbe_RT\tCorrect\n',Settings.SubID,datestr(now),Settings.block_start);
        
        block_ref=reshape(1:length(counterlist.scan_order),[],Settings.blocks);
        
        cd([base_dir '/stims/']);
        for n=1:length(counterlist.scan_order)
            holder=[];
            for m=1:length(counterlist.trial_info(counterlist.scan_order(n)).scan.image_names)
                picname=counterlist.trial_info(counterlist.scan_order(n)).scan.image_names{m};
                pic=imread(char(picname),'jpg');
                holder(m)=Screen(PTB.Window,'MakeTexture',pic);
            end
            scanning.sequences{n}=holder;
            picname=counterlist.trial_info(counterlist.scan_order(n)).scan.bg_name;
            pic=imread(char(picname),'jpg');
            scanning.background(n)=Screen(PTB.Window,'MakeTexture',pic);
        end
        cd(script_dirct);
        
        theData=preAllocate(length(counterlist.scan_order),'scan',true,4);
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,probe_message{end},'center','center',PTB.textColor,PTB.wrap,[],[],2);
        start_scan(Settings,PTB)
        
        for m = Settings.block_start:Settings.blocks
            
            goTime = 0;startTime = GetSecs;goTime=goTime+leadin;
            
            Screen(PTB.Window,'FillRect', PTB.screenColor);Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
            
            for n=1:length(block_ref)
                
                ISIs = ((PTB.ITImax-PTB.ITImin)*rand(1,(length(block_ref)-1)))+PTB.ITImin;ISIs = (round(ISIs*1000))/1000;
                
                trial_index=block_ref(n,m);
                
                theData.scan(trial_index).onset.sequence=goTime;theData.scan(trial_index).sequence_ref=counterlist.scan_order(trial_index);
                theData.scan(trial_index).block=m;theData.scan(trial_index).block_trial=n;
                
                fprintf(fileID,'%d\t%d\t%d\t%d\t%.3f\t',m,n,trial_index,theData.scan(trial_index).sequence_ref,goTime);
                
                goTime=draw_sequence(PTB, scanning.sequences{trial_index}, scanning.background(trial_index), startTime, goTime, image_time, fixation_time);
                    close_textures(scanning.sequences{trial_index});
                fprintf(fileID,'%.3f\t',goTime);
                
                % Probe
                theData.scan(trial_index).onset.probe=goTime;KbQueueStart;goTime=goTime+bettime;
                
                Screen(PTB.Window, 'DrawTexture', Probe(end));Screen(PTB.Window,'Flip');WaitSecs('UntilTime',startTime+goTime);
                
                %ITI & Response collection
                goTime=goTime+readyforarrowsTime;
                
                Screen(PTB.Window,'FillRect', PTB.screenColor);Screen(PTB.Window,'Flip');
                
                WaitSecs('UntilTime',startTime+goTime);KbQueueStop;[~, firstPress]=KbQueueCheck;
                
                theData=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,trial_index,'scan');
                
                fprintf(fileID,'%s\t%.3f\n',theData.scan(trial_index).resp.first,theData.scan(trial_index).respRT.first);
                
                if n~=length(block_ref) %no arrows on last trial
                    num_arrows=floor(ISIs(n))-1;iti_rem=ISIs(n)-num_arrows-.5;
                    [theData,goTime]=arrows(num_arrows,PTB,theData,startTime,goTime,arrowTime,postarrowTime,trial_index,'scan');
                    
                    goTime=goTime+iti_rem;Screen(PTB.Window,'FillRect', PTB.screenColor);
                    Screen(PTB.Window,'Flip');WaitSecs('UntilTime',startTime+goTime);
                end
                
            end
            
            goTime=goTime+leadout;
            Screen(PTB.Window,'FillRect', PTB.screenColor);%ITI, CHANGE IF NO BLANK SCREEN!!!
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
            
            if m==Settings.blocks
                message='Congratulations, you have completed the Scan.  \nThank you very much!';
                
                Screen('TextSize',PTB.Window,PTB.textSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
                Screen(PTB.Window,'Flip');
            else %break between blocks
                savefile=sprintf('%s/data/%d_data_%s_block_%d_run.mat',base_dir,Settings.SubID,date,m);
                save(savefile,'theData','counterlist','Settings');
                
                message='Break \n Please take a minute to rest and relax';
                Screen('TextSize',PTB.Window,PTB.textSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
                start_scan(Settings,PTB)
            end
        end
        
        pause(5);%wait 5 second before clearing screen
        
        if Settings.block_start==1
            savefile=sprintf('%s/data/%d_data_%s_final.mat',base_dir,Settings.SubID,date);
        else
            savefile=sprintf('%s/data/%d_data_%s_startblock_%d_final.mat',base_dir,Settings.SubID,date,Settings.block_start);
        end
        
        save(savefile,'theData','counterlist','Settings');
        
        clear Screen;ShowCursor;
        runn=questdlg('The scan is complete, move on?','Scan Complete','Move on','Quit','Move on');
        switch runn
            case 'Move on'
                RunSeq('settings',Settings,'phase','Post-scan','scan','No');
            case 'Quit'
                Settings.phase{1}='Quit';
        end
        
        %% TEST
    case 'Post-scan'
        tic
        message=['In this last phase of the experiment we will be testing your memory for the order of the items you '...
            'saw during the scanning phase.  For each trial you will be presented with the first item of a sequence, '...
            'and a selection of three item types that were in that series. '... 
            'Each of these item types will be composed of 4 pictures of different exemplars of the itme, includng the '...
            'actual picture you saw in the scanner. Your job is to '...
            'place them in their correct order, based on how they were presented IN THE '...
            'SCANNING PHASE. You can rearrange the item types as you need, and will need to press confirm once you are satisfied '...
            'with your answer'];
        drawMessage_moveOn(PTB,message,'continue instructions')

        message=sprintf(['After ordering the items, you will be shown a series of four pictures for each item in the sequence. '...
            'Your job is to determine which picture of that item was shown in the scanner.  Click on the item that was show during '...
            'the scanning phase.\n\nFor example, an item coild be bells, and the pictures would be four different bells.  '...
            'You are to select the bell that was shown to you during the experiment.\n\n'...
            'After selecting the pictures, you will be asked if the order is the same as the order you saw before the '...
            'scanning phase, different than before the scanning phase, or a new sequence that you did not see before the '...
            'scanning phase.\nIf you are unsure of any answer just made your best guess.\n\n We will walk through an example together before starting']);
        drawMessage_moveOn(PTB,message,'begin')
        
        %length(practice.scan_order)
        practice.scan_order=randperm(length(practice.trial_info));
        for n=1:length(practice.scan_order)
            theData.recall_demo(n).sequence_ref=practice.scan_order(n);
            message='Build the correct sequence based on what you saw IN THE SCANNER';
            theData=sequence_test(PTB,theData,n,practice.trial_info(n).test.image_names(1:end-1),'recall_demo',message);
        end
        
        message=sprintf(['Do you have any questions about the task now that you have practiced it?\n\n'...
            'This phase is all self paced, but try to answer as quickly and accurately as possible.']);
        drawMessage_moveOn(PTB,message,'begin')

        savefiletx=sprintf('%s/data/%d_data_test_%s_%s.txt',base_dir,Settings.SubID,date,datestr(now,13));
        fileID = fopen(savefiletx,'a');
        fprintf(fileID,'Sequence Recall data file for %d at %s\nTrial\tTest\tSequence Ref\tPosition 1\tPosition 2\tPosition 3\tPosition 4\tRT\tPrev Order\tRT\tBG\tRT\tTotal RT\n',Settings.SubID,datestr(now));
        test_order=counterlist.test_order;
        theData.test_order=test_order;
        for n=1:length(test_order)
            theData.scanner_recall(n).sequence_ref=test_order(n);
            theData.scanner_recall(n).seq_type=counterlist.trial_info(test_order(n)).trial_type.number;
            
            message='Build the correct sequence based on what you saw IN THE SCANNER';
            theData=sequence_test(PTB,theData,n,counterlist.trial_info(test_order(n)).test.image_names(1:end-1),'scanner_recall',message);
            %counterlist.trial_info(test_order(n)).test.bg_images_names
            fprintf(fileID,'%d\t%s\t%d\t%s\t%d\t%d\t%d\t%d\t%.3f\t%d\t%.3f\t%d\t%.3f\n',n,'scanner_recall',theData.scanner_recall(n).sequence_ref,...
                counterlist.trial_info(theData.scanner_recall(n).sequence_ref).trial_type.name,theData.scanner_recall(n).final_position(1),theData.scanner_recall(n).final_position(2),...
                theData.scanner_recall(n).final_position(3),theData.scanner_recall(n).final_position(4),...
                theData.scanner_recall(n).seq_time,theData.scanner_recall(n).probe_answer,theData.scanner_recall(n).order_time,...
                counterlist.trial_info(theData.scanner_recall(n).sequence_ref).bg_type.number,theData.scanner_recall(n).total_time);
        end
        toc
        savefile=sprintf('%s/data/%d_data_%s_test.mat',base_dir,Settings.SubID,date);
        save(savefile,'theData','counterlist','Settings');
        
        %goTime=goTime+leadout;
        %Screen(PTB.Window,'FillRect', PTB.screenColor);%ITI, CHANGE IF NO BLANK SCREEN!!!
        %Screen(PTB.Window,'Flip');
        %WaitSecs('UntilTime',startTime+goTime);
        
        message='Congratulations, you have completed the task.  \nThank you very much!';
        
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        pause(5);
        
end
%%
clear Screen;ShowCursor;
end

%% HELPER FUNCTIONS FOR CLEANER CODE -- Any long peice of code called more
%% than once
%%
function theData=preAllocate(num_trials,phase,arrowss,num_arrows)
for n=1:num_trials
    theData.(phase)(n).resp.all='noanswer';
    theData.(phase)(n).resp.first='noanswer';
    theData.(phase)(n).respRT.all=0;
    theData.(phase)(n).respRT.first=0;
    
    theData.(phase)(n).onset.sequence=0;
    theData.(phase)(n).onset.probe=0;
    theData.(phase)(n).sequence_ref=0;
    theData.(phase)(n).correct=false;
    if arrowss
        for arrowcount=1:num_arrows
            theData.arrowresp(n).arrow{arrowcount}='noanswer';
            theData.arrowrespRT(n).arrow(arrowcount)=0;
            theData.arrowtype(n).arrow{arrowcount}='none';
        end
    end
end
end
%%
function drawMessage_moveOn(PTB,message,b_instruction)
    Screen('TextSize',PTB.Window,PTB.textSize);
    DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
    message_add=['Press ''b'' to ' b_instruction];
    Screen('TextSize',PTB.Window,round(PTB.textSize*.75));
    DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-PTB.textSize*2,PTB.textColor);
    Screen(PTB.Window,'Flip');
    getKey('b',PTB.kbNum);
end
%%
function goTime=draw_sequence(PTB, image_list, background_image, onset_time, goTime, image_time, fixation_time)
% Return corrected goTime

Screen(PTB.Window,'FillRect', PTB.screenColor);
Screen(PTB.Window,'Flip');
WaitSecs('UntilTime',goTime);

for i=1:length(image_list)
    
    goTime=goTime+image_time;
    Screen(PTB.Window, 'DrawTexture', background_image,[],PTB.stim_bg_rect);
    Screen(PTB.Window, 'DrawTexture', image_list(i),[],PTB.stim_rect);
    Screen(PTB.Window,'Flip');
    WaitSecs('UntilTime',onset_time+goTime);
    % Fixation
    goTime=goTime+fixation_time;
    Screen(PTB.Window, 'DrawTexture', PTB.fix);
    Screen(PTB.Window,'Flip');
    WaitSecs('UntilTime',onset_time+goTime);
    
end
end
%%
function [theData,pressed,RT]=getKeyPress_correct(firstPress,startSecs,trigger_char,theData,trial,phase)
keypresses = find(firstPress);

if ~isempty(keypresses)
    
    hold_time=firstPress(find(firstPress)) - startSecs;
    hold_press=keypresses;
    hold=cat(1,hold_time,hold_press);
    ordered=sortrows(hold',1);
    
    theData.(phase)(trial).resp.all=KbName(ordered(:,2));
    theData.(phase)(trial).respRT.all=ordered(:,1);
    
    if ~ismember(trigger_char,KbName(ordered(1,2)))
        %strcmp(KbName(ordered(1,2)),trigger_char)
        if iscell(theData.(phase)(trial).resp.all)
            theData.(phase)(trial).resp.first= theData.(phase)(trial).resp.all{1}(1);
        else
            theData.(phase)(trial).resp.first= theData.(phase)(trial).resp.all(1);
        end
        theData.(phase)(trial).respRT.first= theData.(phase)(trial).respRT.all(1);
    elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
        if iscell(theData.(phase)(trial).resp.all)
            theData.(phase)(trial).resp.first= theData.(phase)(trial).resp.all{2}(1);
        else
            theData.(phase)(trial).resp.first= theData.(phase)(trial).resp.all(2);
        end
        theData.(phase)(trial).respRT.first= theData.(phase)(trial).respRT.all(2);
    end
end
pressed=theData.(phase)(trial).resp.first;
RT=theData.(phase)(trial).respRT.first;
end
%%
function start_scan(Settings,PTB)
switch Settings.scan
    case 'Yes'
        message_add='Experimentor press ''b'' to wait for trigger';
        Screen('TextSize',PTB.Window,round(PTB.textSize*.75));
        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-PTB.textSize*2,PTB.textColor);
        Screen(PTB.Window,'Flip');
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        getKey('b',PTB.kbNum);
    case 'No'
        message_add='Press ''b'' to begin';
        Screen('TextSize',PTB.Window,round(PTB.textSize*.75));
        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-PTB.textSize*2,PTB.textColor);
    case 'Yes - W/O Trigger'
        message_add='Experimentor press ''b'' to begin';
        Screen('TextSize',PTB.Window,round(PTB.textSize*.75));
        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-PTB.textSize*2,PTB.textColor);
end
Screen(PTB.Window,'Flip');
switch  Settings.scan
    case 'Yes'
        message='Waiting for trigger...';
        Screen('TextSize',PTB.Window,PTB.textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,PTB.wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        getKey(PTB.trigger_char,PTB.boxNum);
        WaitSecs(0.001);
    case {'No','Yes - W/O Trigger'}
        getKey('b',PTB.kbNum);
end
end
%%
function [theData,goTime]=arrows(num_arrows,PTB,theData,startTime,goTime,arrowTime,postarrowTime,n,phase)
for arrowcount = 1:num_arrows
    
    arrowset = Shuffle([1 2]);
    arrow = arrowset(1);
    goTime = goTime + arrowTime;
    KbQueueStart;
    if mod(arrow,2)
        arrowtype = 'left';
        Screen(PTB.Window, 'DrawTexture', PTB.L_arrow);
        Screen(PTB.Window,'Flip');
    else
        arrowtype = 'right';
        Screen(PTB.Window, 'DrawTexture', PTB.R_arrow);
        Screen(PTB.Window,'Flip');
    end
    
    WaitSecs('UntilTime',startTime+goTime);
    
    if arrowcount ~= num_arrows
        % Post-arrow fixation period
        goTime = goTime + postarrowTime;
        Screen(PTB.Window, 'DrawTexture', PTB.fix);
        Screen(PTB.Window,'Flip');
    end
    
    WaitSecs('UntilTime',startTime+goTime);
    
    KbQueueStop; %stop recording button responces
    [~, firstPress]=KbQueueCheck;
    
    [~,keys,RT]=getKeyPress_correct(firstPress,startTime,PTB.trigger_char,theData,n,phase);
    
    theData.arrowresp(n).arrow{arrowcount}=keys;
    theData.arrowrespRT(n).arrow(arrowcount)=RT;
    theData.arrowtype(n).arrow{arrowcount}=arrowtype;
    
end
end
%%
function theData=sequence_test(PTB,theData,n,test_images,test_name,message)
%bg_images,
%test_images(5:end)=[];

first_image=test_images{1};
picname=first_image;
pic=imread(char(picname),'jpg');
PTB.target_img(1)=Screen(PTB.Window,'MakeTexture',pic);

test_images(1)=[];

index=randperm(length(test_images));
for c=1:length(test_images)
    grid_index{c}=randperm(length(test_images{c}));
    for v=1:length(test_images{c})
        picname=test_images{index(c)}{grid_index{c}(v)};
        pic=imread(char(picname),'jpg');
        moving_img{c}(v)=Screen(PTB.Window,'MakeTexture',pic);
    end
end

% for d=1:length(exmp_names)
%     index_exempt=randperm(length(exmp_names{d}));
%     for c=1:length(exmp_names{d})
%         picname=exmp_names{index(d)}{index_exempt(c)};
%         pic=imread(char(picname),'jpg');
%         exmpt_img{d}(c)=Screen(PTB.Window,'MakeTexture',pic);
%     end
% end

baseRect = [0 0 150 150];

xMax=PTB.xMax;
yMax=PTB.yMax;
xCenter=PTB.xCenter;
yCenter=PTB.yCenter;

red = [225 0 0];
blue = [0 0 225];
green= [0 225 0];
yellow=[0 225 225];
highlight_grey=100;
base_grey=50;

[xCent(1),yCent(1)]=RectCenter([0 0 .25*xMax yCenter]);
    target_rect{1}=CenterRectOnPointd(baseRect,xCent(1),yCent(1));
[xCent(2),yCent(2)]=RectCenter([.25*xMax 0 xCenter yCenter]);
    target_rect{2}=CenterRectOnPointd(baseRect,xCent(2),yCent(2));
[xCent(3),yCent(3)]=RectCenter([xCenter 0 .75*xMax yCenter]);
    target_rect{3}=CenterRectOnPointd(baseRect,xCent(3),yCent(3));
[xCent(4),yCent(4)]=RectCenter([.75*xMax 0 xMax yCenter]);
    target_rect{4}=CenterRectOnPointd(baseRect,xCent(4),yCent(4));

[xCent_e(1),yCent_e(1)]=RectCenter([0 .25*yMax .25*xMax .75*yMax]);
    exemp_rect{1}=CenterRectOnPointd(baseRect,xCent_e(1),yCent_e(1));
[xCent_e(2),yCent_e(2)]=RectCenter([.25*xMax .25*yMax xCenter .75*yMax]);
    exemp_rect{2}=CenterRectOnPointd(baseRect,xCent_e(2),yCent_e(2));
[xCent_e(3),yCent_e(3)]=RectCenter([xCenter .25*yMax .75*xMax .75*yMax]);
    exemp_rect{3}=CenterRectOnPointd(baseRect,xCent_e(3),yCent_e(3));
[xCent_e(4),yCent_e(4)]=RectCenter([.75*xMax .25*yMax xMax .75*yMax]);
    exemp_rect{4}=CenterRectOnPointd(baseRect,xCent_e(4),yCent_e(4));

pop_outRect=[exemp_rect{1}(1)-20 exemp_rect{1}(2)-20 exemp_rect{4}(3)+20 exemp_rect{4}(4)+20];

[xCent(5),yCent(5)]=RectCenter([xCenter yCenter .75*xMax .75*yMax]);
    moving_rect{4}=CenterRectOnPointd(baseRect,xCent(5),yCent(5));
[xCent(6),yCent(6)]=RectCenter([.75*xMax yCenter xMax .75*yMax]);
    moving_rect{2}=CenterRectOnPointd(baseRect,xCent(6),yCent(6));
[xCent(7),yCent(7)]=RectCenter([xCenter .75*yMax .75*xMax yMax]);
    moving_rect{3}=CenterRectOnPointd(baseRect,xCent(7),yCent(7));
[xCent(8),yCent(8)]=RectCenter([.75*xMax .75*yMax xMax yMax]);
    moving_rect{1}=CenterRectOnPointd(baseRect,xCent(8),yCent(8));
[xCent(9),yCent(9)]=RectCenter([.25*xMax yCenter xCenter .75*yMax]);
    moving_rect{6}=CenterRectOnPointd(baseRect,xCent(9),yCent(9));
[xCent(10),yCent(10)]=RectCenter([.25*xMax .75*yMax xCenter yMax]);
    moving_rect{5}=CenterRectOnPointd(baseRect,xCent(10),yCent(10));

moving_rect=moving_rect(1:length(moving_img));

[xCent(11),yCent(11)]=RectCenter([0 .75*yMax .25*xMax yMax]);
    button_rect=CenterRectOnPointd([0 0 250 166],xCent(11),yCent(11));

probe_button_rec{1}=CenterRectOnPointd([0 0 250 166],.25*xMax,.75*yMax);
probe_button_rec{2}=CenterRectOnPointd([0 0 250 166],xCenter,.75*yMax);
probe_button_rec{3}=CenterRectOnPointd([0 0 250 166],.75*xMax,.75*yMax);

selected=false;
done=false;

for m=1:length(moving_rect)
    Image(m).selected=false;
    Image(m).placed=false;
    Image(m).exmp_placed=false;
end
for m=1:length(target_rect)
    Target(m).filled=false;
    Target(m).filled_with=0;
end

Target(1).filled=true;
Target(1).filled_with=1;

Screen(PTB.Window,'FillRect', PTB.screenColor);
Screen(PTB.Window,'Flip');%starts blank screen

SetMouse(xCenter, yCenter, PTB.Window);
first_move=false;
log.time(1)=0;
log.first_move{1}=false;
log.all_full{1}=false;
log.selections{1}=Image(:).selected;
log.placed{1}=Target(:).filled_with;
log.finished{1}=done;

startTime=GetSecs;
while ~done
    
    Screen('TextSize',PTB.Window,round(xMax/75));
    DrawFormattedText(PTB.Window,message,'center',.5*target_rect{1}(2),PTB.textColor);
    Screen('TextSize',PTB.Window,round(xMax/100));
    DrawFormattedText(PTB.Window,'Place images below in the correct order above',xCenter,'center',PTB.textColor);
    
    [mx,my,buttons]=GetMouse(PTB.Window);
    
    inside_button=IsInRect(mx,my,button_rect);
    
    something_happened=false;
    
    if mx~=xCenter && my~=yCenter && ~first_move
        something_happened=true;
        first_move=true;
    end
    
    for m=1:length(moving_rect)
        
        [cx(m),cy(m)]=RectCenter(moving_rect{m});
        
        inside_moving(m)=IsInRect(mx,my,moving_rect{m});
        
        if ~Image(m).selected
            color{m}=[0 0 0];
            sx(m)=cx(m);sy(m)=cy(m);
        end
        
        if inside_moving(m)==1 && ~Image(m).selected && ~selected
            color{m}=green;
        end
        
        if inside_moving(m)==1 && sum(buttons)>0 && ~Image(m).selected && ~selected
            dx(m)=mx-cx(m);dy(m)=my-cy(m);
            Image(m).selected=true;
            selected=true;
            something_happened=true;
        end
        
        if Image(m).selected && sum(buttons)>0
            color{m}=blue;
            sx(m)=mx-dx(m);sy(m)=my-dy(m);
        end
        
        tar_color{1}=[0 0 0];
        for h=2:length(target_rect)
            [fx,fy]=RectCenter(target_rect{h});
            inside_target=IsInRect(mx,my,target_rect{h});
            
            tar_color{h}=[0 0 0];
            if selected && inside_target
                tar_color{h}=yellow;
            end
            
            if Image(m).selected && inside_target && sum(buttons) <= 0 && ~Target(h).filled
                sx(m)=fx;sy(m)=fy;
                color{m}=[0 0 0];
                Image(m).selected=false;
                something_happened=true;
            end
        end
        
        if sum(buttons) <= 0 && selected
            something_happened=true;
        end
        
        if sum(buttons) <= 0
            Image(m).selected=false;
            selected=false;
        end
        
        moving_rect{m}=CenterRectOnPointd(baseRect, sx(m), sy(m));
    end
    
    all_full=true;
    for h=2:length(target_rect)
        [fx,fy]=RectCenter(target_rect{h});
        for m=1:length(moving_rect)
            [cx(m),cy(m)]=RectCenter(moving_rect{m});
            if fx==cx(m) && fy==cy(m)
                Target(h).filled=true;Target(h).filled_with=m;
                break
            else
                Target(h).filled=false;Target(h).filled_with=0;
            end
        end
    end
    for h=1:length(target_rect)
        if Target(h).filled==false
            all_full=false;
        end
    end
    
    DrawFormattedText(PTB.Window,'Press Continue to confirm sequence',button_rect(1),button_rect(2)-20,PTB.textColor);
    if all_full
        Screen(PTB.Window, 'DrawTexture',PTB.cont,[],button_rect);
    else
        Screen(PTB.Window, 'DrawTexture',PTB.cont_grey,[],button_rect);
    end
    
    if all_full && inside_button && sum(buttons)>0
        something_happened=true;done=true;
    end
    
    for j=1:length(target_rect)
        Screen(PTB.Window,'DrawTexture',PTB.target_img(j),[],target_rect{j});
        Screen(PTB.Window,'FrameRect',tar_color{j},target_rect{j},5);
    end
    for g=length(moving_img):-1:1
        draw_grid(PTB,moving_img{g},moving_rect{g});
        Screen(PTB.Window,'FrameRect',color{g},moving_rect{g},5);
    end
    
    if something_happened
        log.time(end+1)=GetSecs-startTime;
        placing_ref=length(log.time);
        log.first_move{end+1}=first_move;
        log.all_full{end+1}=all_full;
        for z=1:length(Image)
            log.selections{placing_ref}(z)=Image(z).selected;
        end
        for c=1:length(Target)
            if Target(c).filled_with>0 && c~=1
                log.placed{placing_ref}(c)=index(Target(c).filled_with);
            elseif c==1
                log.placed{placing_ref}(c)=1;
            else
                log.placed{placing_ref}(c)=0;
            end
        end
        log.finished{end+1}=done;
    end
    
    Screen(PTB.Window,'Flip');
    
end

theData.(test_name)(n).seq_time=GetSecs-startTime;

theData.(test_name)(n).final_position(1)=1;
for h=2:length(target_rect)
    exemp_test(h-1)=Target(h).filled_with;
    theData.(test_name)(n).final_position(h)=index(Target(h).filled_with)+1;
    Image(Target(h).filled_with).placed=true;
    Image(Target(h).filled_with).exmp_placed=false;
end
final_moving_img=[];
exmp_start_full=GetSecs;
for p=1:length(exemp_test)
    exmp_starts(p)=GetSecs;
    selected=false;
    while ~selected

        Screen(PTB.Window,'FillRect',base_grey,pop_outRect);
        Screen(PTB.Window,'FillPoly',highlight_grey,...
            [moving_rect{exemp_test(p)}(3), moving_rect{exemp_test(p)}(4);...
            moving_rect{exemp_test(p)}(1), moving_rect{exemp_test(p)}(4);...
            pop_outRect(1), pop_outRect(2);...
            pop_outRect(3), pop_outRect(2)]);

        
        Screen(PTB.Window,'DrawTexture',PTB.target_img(1),[],target_rect{1});
        Screen(PTB.Window,'FrameRect',tar_color{1},target_rect{1},5);
        DrawFormattedText(PTB.Window,'Select the image that you saw in this sequences',...
            'center',pop_outRect(2)-25,PTB.textColor);
        for g=length(exemp_test):-1:1
            if Image(exemp_test(g)).placed
                if Image(exemp_test(g)).exmp_placed
                    Screen(PTB.Window,'DrawTexture',final_moving_img(exemp_test(g)),[],moving_rect{exemp_test(g)});            
                else
                    draw_grid(PTB,moving_img{exemp_test(g)},moving_rect{exemp_test(g)});
                end
                Screen(PTB.Window,'FrameRect',color{exemp_test(g)},moving_rect{exemp_test(g)},5);
            end
        end

        [mx,my,buttons]=GetMouse(PTB.Window);
        
        Screen(PTB.Window,'FrameRect',highlight_grey,moving_rect{exemp_test(p)},5);
        for m=1:length(moving_rect{exemp_test(p)}) %length(exemps{p})
            Screen(PTB.Window,'DrawTexture',moving_img{exemp_test(p)}(m),[],exemp_rect{m});
            Screen(PTB.Window,'FrameRect',0,exemp_rect{m},5);
            inside_exmp=IsInRect(mx,my,exemp_rect{m});
            
            if inside_exmp && sum(buttons)<1
                Screen(PTB.Window,'FrameRect',green,exemp_rect{m},5);
            end
            
            if inside_exmp && sum(buttons)>0
                Image(exemp_test(p)).exmp_placed=true;
                theData.(test_name)(n).index_choice(p)=grid_index{exemp_test(p)}(m);
                selected=true;
                Screen(PTB.Window,'FrameRect',blue,exemp_rect{m},5);
                final_moving_img(exemp_test(p))=moving_img{exemp_test(p)}(m);
            end
        end

        Screen(PTB.Window,'Flip');
    end
    theData.(test_name)(n).exmp_times(p)=GetSecs-exmp_starts(p);
    WaitSecs(.20);
end

theData.(test_name)(n).exmp_time_full=GetSecs-exmp_start_full;

WaitSecs(.20);
order_start=GetSecs;
answered=false;
while ~answered
    Screen(PTB.Window,'DrawTexture',PTB.target_img(1),[],target_rect{1});
    Screen(PTB.Window,'FrameRect',tar_color{1},target_rect{1},5);
    DrawFormattedText(PTB.Window,['Is this order the SAME as the order you saw before the scanning phase, '...
        'DIFFERENT than before the scanning phase, or a NEW sequence that you did not see before the scanning phase'],...
        'center','center',PTB.textColor);
    for g=length(exemp_test):-1:1
        if Image(exemp_test(g)).placed
            Screen(PTB.Window,'DrawTexture',final_moving_img(exemp_test(g)),[],moving_rect{exemp_test(g)});
            Screen(PTB.Window,'FrameRect',color{exemp_test(g)},moving_rect{exemp_test(g)},5);
        end
    end
    
    [mx,my,buttons]=GetMouse(PTB.Window);
    for m=1:length(PTB.button)
        Screen(PTB.Window,'DrawTexture',PTB.button(m),[],probe_button_rec{m});
        inside_Testbutton=IsInRect(mx,my,probe_button_rec{m});
        if inside_Testbutton && sum(buttons)>0
            answered=true;
            theData.(test_name)(n).probe_answer=m;
        end
    end
    Screen(PTB.Window,'Flip');
end

theData.(test_name)(n).order_time=GetSecs-order_start;

theData.(test_name)(n).total_time=GetSecs-startTime;
theData.(test_name)(n).log=log;
close_textures(moving_img);
end
%%
function draw_grid(PTB,moving_img,rect)
a=rect(1);
b=rect(2);
c=rect(3);
d=rect(4);

[e,f]=RectCenter(rect);

grid_rect{1}=[a,b,e,f];
grid_rect{2}=[e,b,c,f];
grid_rect{3}=[a,f,e,d];
grid_rect{4}=[e,f,c,d];

for g=1:length(moving_img)
    Screen(PTB.Window,'DrawTexture',moving_img(g),[],grid_rect{g});
end

end
%%
function getKey(key,k)
% Janice Chen 02/01/06
while 1
    while 1
        [keyIsDown,~,keyCode] = KbCheck(k);
        if keyIsDown
            while KbCheck
            end
            break;
        end
    end
    theAnswer = KbName(keyCode);
    if ismember(key,theAnswer)  % this takes care of numbers too, where pressing 1 results in 1!
        break
    end
end
end
%%
function close_textures(texture_list)
    for o=1:length(texture_list)
        if iscell(texture_list)
            for z=1:length(texture_list{o})
               Screen('Close',texture_list{o}(z)); 
            end
        else
            Screen('Close',texture_list(o)); 
        end
    end
end

%%
function myCleanupFun(PTB)
cd(PTB.script_dirct);
ShowCursor;
Screen('Resolution', PTB.screenNumber, [PTB.old.width], [PTB.old.height]);
Screen('CloseAll')
end
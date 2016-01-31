function theData = runMM

clear all;
commandwindow; % bring focus to command window.

% warning off;
% fprintf('REMEMBER TO TURN OFF NETWORK CONNECTION OR ELSE MATLAB WILL CRASH DURING EXPT.\n')

script_path=which('runMM.m');
script_dirct=fileparts(script_path);
cd(script_dirct);

fprintf('\n');
subID=input('Enter Subject Number: ','s'); %asks for subject number

%navigates to the list directory and lists all the lists in that dir that
%start with the subject number
cd ../lists; %%be careful with these hard paths for cd

fprintf('\n========================================\n\n');
call=sprintf('ls %s_list*',subID);
unix(call);

fprintf('\n========================================\n');
counterbalance=input('Enter the correct subject counterbalancing list file from above: ','s'); %counterbalance list set by user

load(counterbalance);

fprintf('\n========================================\n');
PTB.scan=input('Is this in the scanner? (Enter 1 for yes, 2 for no, 3 for in scanner w/o trigger) '); %behavior or scan ====== everything set for only behav now 2/1/12
fprintf('\n========================================\n');

PTB.localizer=2;

if PTB.scan==2
    PTB.run=input('Is this learning(1), scan/test practice(2), test(3), or localizer only(4)?\n\nEnter the number for the correct session: ');%session, what the script will do
    fprintf('\n========================================\n');
    if PTB.run==1
        PTB.day=input('Is this day(1) or day(2) of training?: ');
        switch(PTB.day)
            case 1
                %PTB.training=1;%reduces to one view on day1
                PTB.training=2;
            case 2
                PTB.training=1;
            otherwise
                fprintf('day of training can only be 1 or 2');
        end
    elseif PTB.run==3
        PTB.block_start=1;
        fprintf('\n========================================\n');
        PTB.block_start=input('Strating with what block (1-8)? ');%can restart from later blocks in problems encountered, can't yet append to earlier scans
        fprintf('\n========================================\n');
        PTB.localizer=input('Run localizer after test (yes(1)/no(2))? ');
    end
else
    PTB.run=input('Is this test(3), or localizer only(4)?\n\nEnter the number for the correct session: ');
    if PTB.run==3
        PTB.block_start=1;
        fprintf('\n========================================\n');
        PTB.block_start=input('Strating with what block? (Default=1) ');%can restart from later blocks in problems encountered, can't yet append to earlier scans
        fprintf('\n========================================\n');
        PTB.localizer=input('Run localizer after test (yes(1)/no(2))? ');
    end
end

cd(script_dirct);

%%%%%%%%%%%%%  BEGIN DARA'S CODE FOR QUERYING THE DEVICES
%%%%%%%%%%%%%
%numDevices=PsychHID('NumDevices');
devices=PsychHID('Devices');

% first find all keyboard devices
keydevs=[];
for d=1:length(devices),
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

switch PTB.scan
    case {1,3}
        PTB.boxNum=inputDevice(1);%bbox
        PTB.kbNum=inputDevice(3);%keyboard
    case 2
        %gets device numbers for subject responces
        PTB.boxNum=inputDevice(3);%keyboard
        PTB.kbNum=inputDevice(3);%keyboard
end

KbQueueCreate(PTB.boxNum);
%PTB.on=0; %Screen no on yet... not sure how to use this yet, for scanning... i think


trigger_char='5'; % for new trigger at BMC


%Times for prescan
preStart=2.0;
pairOn=6.0;
fix_time=2.0;
%Times for test
leadin=5.0;%two TRs, 
bettime=2.0;
delay=8.0;
probe=2.0;
leadout=8.0; %leadout same as the ITI time, so last trial is same lenght as other trials
%times for arrows in iti.  ITI is 8 sec total
readyforarrowsTime = 1.0;
arrowTime = 1.0; % the arrows during the ITI
postarrowTime = (2/3);
readyfornexttrialTime = 1.0+(2-3*postarrowTime);
%times for localizer
imagetime=1.0;
offtime=.875; %7/8
leadout_mvpa=5.0+offtime; %five seconds after the last block, each block includes the last offtime, so need to add it.

if PTB.run==1
    [learning, trial, PTB.blocks, PTB.blocks_stim]=trial_info(counter_lists);%sets up all the trial info and block info, see script
    theData.trial=trial;%saves the trial info in theData
    
    cd(script_dirct);
elseif PTB.run==3
    [learning, trial, PTB.blocks, PTB.blocks_stim]=trial_info(counter_lists);%sets up all the trial info and block info, see script
    theData.trial=trial;%saves the trial info in theData
    if PTB.localizer==1
        cd(script_dirct);
        
        localizer_info=loc_info(counter_lists);%sets up all the trial info and block info, see script
        theLocalizer.info=localizer_info;%saves the trial info in theData
    end
elseif PTB.run==4
    cd(script_dirct);
    
    localizer_info=loc_info(counter_lists);%sets up all the trial info and block info, see script
    theLocalizer.info=localizer_info;%saves the trial info in theData
end

PTB.screenNumber=0;
PTB.screenColor=220; %%grey
PTB.textColor=0;  %%black

old=Screen('Resolution', PTB.screenNumber, [], []);
Screen('Resolution', PTB.screenNumber, 800, 600);

[PTB.Window, PTB.myRect]= Screen(PTB.screenNumber, 'OpenWindow', PTB.screenColor, []);

Screen(PTB.Window,'FillRect', PTB.screenColor);
Screen(PTB.Window,'Flip');%starts blank screen

HideCursor;

cd ../stims

% Set params for W x H stimulus dimensions
stim_width = 300; %420; %560;
stim_height = 300; %315; %420;
horz_center = (PTB.myRect(3)-PTB.myRect(1))/2;
vert_center = (PTB.myRect(4)-PTB.myRect(2))/2;
RectLeft = horz_center - stim_width/2;
RectTop = vert_center - stim_height/2;
RectRight = horz_center + stim_width/2;
RectBottom = vert_center + stim_height/2;

% Load fixation
fileName = 'fix.jpg';
pic = imread(fileName);
fix = Screen(PTB.Window,'MakeTexture', pic);

% Load Arrow Keys
fileName = 'R_arrow.jpg';
pic = imread(fileName);
R_arrow = Screen(PTB.Window,'MakeTexture', pic);

fileName = 'L_arrow.jpg';
pic = imread(fileName);
L_arrow = Screen(PTB.Window,'MakeTexture', pic);

textSize=20;
instructionSize=15;
wrap=90;


cd(script_dirct);

switch(PTB.run)
    case 1 %learning phase
        
        RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));%%Resets the randomization list, otherwise would call the same random list every time matlab restarts
        
        message='loading images...'; %screen says loading images if it takes a while to make all the textures
        Screen('TextSize',PTB.Window,textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        cd ../stims;
        for n=1:length(learning) %pre-makes textures for trials
            picname=learning(n).stim_name;
            pic=imread(char(picname),'jpg');
            learning(n).stim_image=Screen(PTB.Window,'MakeTexture',pic);
        end
        cd(script_dirct);
        
        switch(PTB.day)
            case 1 %day1
                
                cd ../stims;
                practice=struct;
                load practice.mat;%loads a structure that contains all the info for practice trials
                for n=1:length(practice) %pre-makes textures for practice
                    picname=practice(n).stim_name;
                    pic=imread(char(picname),'jpg');
                    practice(n).stim_image=Screen(PTB.Window,'MakeTexture',pic);
                end
                
                cd(script_dirct);
                
                %intructions on screen
                message=['In this experiment you will be shown pairs of names and pictures for a memory test later.'...
                    ' Your job in this first part is to try to associate the name with the picture so that you can later'...
                    ' identify the picture that was paired with a name.  Try to remember as many details about the picture'...
                    ' as possible, because they will be needed for the memory test.  A name and a picture will be presented'...
                    ' together for 6 seconds before a new pair is presented, you do not need to do anything while the images'...
                    ' are being presented other than try to learn the pairs. \n Do you have any questions? \n\n'...
                    'We will start with a quick practice run so that you can see the format and pace of the task.'];
                Screen('TextSize',PTB.Window,instructionSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                message_add='Press ''b'' to begin';
                Screen('TextSize',PTB.Window,round(instructionSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
                
                goTime = 0;
                
                getKey('b',PTB.kbNum); %waites for button press to start
                
                startTime = GetSecs;%starts everything from when 'b' is pressed
                goTime=goTime+preStart;%lead in time
                
                Screen(PTB.Window,'FillRect', PTB.screenColor);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime); %empty screen for lead in time
                
                index=randperm(length(practice));%random order of practice presentaion
                
                for n=1:length(practice)%
                    i=index(n);
                    goTime=goTime+pairOn;
                    message=practice(i).name;%name pair
                    Screen('TextSize',PTB.Window,textSize*2);
                    DrawFormattedText(PTB.Window,message,'center',textSize*4,PTB.textColor);
                    pic=practice(i).stim_image;%image pair
                    Screen(PTB.Window, 'DrawTexture', pic,[],[RectLeft RectTop, RectRight, RectBottom]);
                    Screen(PTB.Window,'Flip');
                    WaitSecs('UntilTime',startTime+goTime);
                    
                    %fixation in between trials
                    if n~=length(practice)%not on last trial
                        goTime=goTime+fix_time;
                        Screen(PTB.Window, 'DrawTexture', fix);
                        Screen(PTB.Window,'Flip');
                        WaitSecs('UntilTime',startTime+goTime);
                    end
                end
                
                message=['Do you have any questions about the task now that you have practiced it?'...
                    '\n Now we are going to start the task.  The task will run for about 45 minutes, in six blocks'...
                    ' of seven minutes.  You will see each pair twice.  Between the blocks will be a period for you to rest'...
                    ' and relax your mind.  Once you are ready to move onto the next block press B to continue.'...
                    '\n Are you ready?'];
                %You will see each pair twice. 44 mins, six blocks
                Screen('TextSize',PTB.Window,instructionSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                message_add='Press ''b'' to continue';
                Screen('TextSize',PTB.Window,round(textSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
                
                getKey('b',PTB.kbNum);
            case 2 %day2
                
                pairOn=pairOn-2;%shorten time for day2
                %intructions on screen
                message=['In this experiment you will be shown pairs of names and picture for a memory test later. '...
                    'Your job in this first part is to try to associate the name with the picture so that you can later '...
                    'identify the picture that was paired with a name.  Try to remember as many details about the picture '...
                    'as possible, because they will be needed for the memory test.  A name and a picture will be presented '...
                    'together for 4 seconds before a new pair is presented, you do not need to do anything while the images '...
                    'are being presented other than try to learn the pairs. \n Do you have any questions?'];
                Screen('TextSize',PTB.Window,instructionSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                message_add='Press ''b'' to begin';
                Screen('TextSize',PTB.Window,round(instructionSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
                
                getKey('b',PTB.kbNum);
        end
        
        for m=1:PTB.training%number of training blocks
            
            goTime = 0;
            index=randperm(length(learning));%mixes the order each block
            
            startTime = GetSecs;
            goTime=goTime+preStart;%lead in
            
            Screen(PTB.Window,'FillRect', PTB.screenColor);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
            
            for i=1:length(learning)
                %pairs
                n=index(i);
                goTime=goTime+pairOn;
                message=learning(n).name;
                Screen('TextSize',PTB.Window,textSize*2);
                DrawFormattedText(PTB.Window,message,'center',textSize*4,PTB.textColor);
                pic=learning(n).stim_image;
                Screen(PTB.Window, 'DrawTexture', pic,[],[RectLeft RectTop, RectRight, RectBottom]);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
                %fixation
                goTime=goTime+fix_time;
                if i==length(learning) || i==round(length(learning)/2)%no fixation for last trial or before break
                    Screen(PTB.Window,'FillRect', PTB.screenColor);
                    Screen(PTB.Window,'Flip');
                    WaitSecs('UntilTime',startTime+goTime);
                else%brief lead out for last trial
                    Screen(PTB.Window, 'DrawTexture', fix);
                    Screen(PTB.Window,'Flip');
                    WaitSecs('UntilTime',startTime+goTime);
                end
                if i==round(length(learning)/3) || i==round(length(learning)*(2/3))%A break a third way through the stim presentation
                    message='Break \n Please take a minute to rest and relax';
                    Screen('TextSize',PTB.Window,textSize);
                    DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                    message_add='Press ''b'' to continue';
                    Screen('TextSize',PTB.Window,round(textSize*.75));
                    DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                    Screen(PTB.Window,'Flip');
                    getKey('b',PTB.kbNum);
                    goTime = 0;%restarts go time for the break
                    startTime = GetSecs;
                    goTime=goTime+preStart;
                end
            end
            
            if m == PTB.training %end of training
                switch(PTB.day)
                    case 1
                        message='Today''s part of the experiment is complete, you will be returning tomorrow for the second part.\n\n\nPress ''b'' to end.';
                        Screen('TextSize',PTB.Window,instructionSize);
                        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                        Screen(PTB.Window,'Flip');
                        getKey('b',PTB.kbNum);
                        clear Screen;
                    case 2
                        message='This part of the experiment is complete, now we will move onto the second part.\n\n\nPress ''b'' to end.';
                        Screen('TextSize',PTB.Window,instructionSize);
                        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                        Screen(PTB.Window,'Flip');
                        getKey('b',PTB.kbNum);
                        clear Screen;
                end
            else%breaks between blocks
                message='Break \n Please take a minute to rest and relax';
                Screen('TextSize',PTB.Window,textSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                message_add='Press ''b'' to continue';
                Screen('TextSize',PTB.Window,round(textSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
                getKey('b',PTB.kbNum);
                
            end
        end
    case 2 %practice
        
        message='loading images...';
        Screen('TextSize',PTB.Window,textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        cd ../stims;
        practice=struct;
        load practice.mat;
        theData.practice=practice;%saves the trial info in theData
        
        %populates theData
        for n=1:length(practice)
            theData.resp.bet{n}= 'noanswer';
            theData.resp.probe{n}= 'noanswer';
            theData.all_resp.bet{n} = 'noanswer';
            theData.all_resp.probe{n} = 'noanswer';
            theData.all_respRT.bet{n} = 'noanswer';
            theData.all_respRT.probe{n} = 'noanswer';
            theData.respRT.bet(n) = 0;
            theData.respRT.probe(n) = 0;
            theData.onset.bet(n) = 0;
            theData.onset.probe(n) = 0;
        end
        
        %pre-makes textured for practice
        for n=1:length(practice)
            picname=practice(n).stim_name;
            pic=imread(char(picname),'jpg');
            practice(n).stim_image=Screen(PTB.Window,'MakeTexture',pic);
        end
        for n=1:length(practice)
            picname=practice(n).probe_name;
            pic=imread(char(picname),'jpg');
            practice(n).probe_image=Screen(PTB.Window,'MakeTexture',pic);
        end
        
        %instructions --- Theres a lot for this part, have to press through
        cd(script_dirct);
        
        savefiletx=sprintf('%s_data_%s_%s_practicelog.txt',subID,date,datestr(now,13));
        fileID = fopen(savefiletx,'a');
        fprintf(fileID,'MM practice data file for %s at %s \nTrial\tBet_onset\tBet_Resp\tBet_RT\tProbe_onset\tProbe_Resp\tProbe_RT\tCorrect\n',subID,datestr(now));
        
        message=['Now we will be testing your memory for the name-image pairs you learned yesterday.  You will be shown a '...
            'name that you saw in the training session, which will be on the screen for about 2 seconds.  While the name is '...
            'on the screen you will give a rating of the strength of your memory for the image that was paired with that name. '...
            'Indicate a STRONG MEMORY, where you can perfectly picture the paired image, with the 1 key; a MODERATE MEMORY, '...
            'where you remember some of the details of the paired image, the 2 key; a WEAK MEMORY, where you '...
            'remember the name or content of the paired image, but few visual details, with the 3 key; and NO MEMORY, where you dont remember '...
            'anything about the paired image with the 4 key.'];
        Screen('TextSize',PTB.Window,instructionSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        message_add='Press ''b'' to continue instructions';
        Screen('TextSize',PTB.Window,round(instructionSize*.75));
        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
        Screen(PTB.Window,'Flip');
        
        message=['After the name there will be a delay of about 8 seconds, during which there will only be a fixation cross '...
            'on the screen.  During the delay you should picture the paired image in your head, as well as you can remember.'...
            '\nFollowing the delay you will be see a picture, and your job is to indicate whether that picture is the '...
            'EXACT SAME PICTURE as the image that was previously paired with the name with the 1 key; an image that is a '...
            'SIMILAR PICTURE to previously paired image (has similar feature in the image, but not an exact match) with the 2 key; '...
            'or an image that is a VERY DIFFERENT PICTURE to the paired image (nothing similar about the image), with the 3 key; '...
            'additionally, if you DO NOT KNOW if the picture is a match since you do not remember the original image press the 4 key.'...
            '\nBetween each trial you will see series of four arrows.  For each arrow indicate the direction the arrow is pointing, '...
            '1 for left, 2 for right. \n\nAny Questions?'];
        Screen('TextSize',PTB.Window,instructionSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        message_add='Press ''b'' to continue instructions';
        Screen('TextSize',PTB.Window,round(instructionSize*.75));
        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
        getKey('b',PTB.kbNum);
        Screen(PTB.Window,'Flip');
        
        message=['Just to repeat, for each trial you will see a name that you learned before and will make a judgment about '...
            'your memory for the paired image, then there will be a delay, where you should picture the paired image, '...
            'followed by an image where you will indicate if it is an exact match, similar image, very different image, '...
            'or dont know, then a new trial will start.  You will have only two seconds to make your responses so be sure '...
            'to make response in that time. We will start with a few practice trials.'];
        Screen('TextSize',PTB.Window,instructionSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        message_add='Press ''b'' to begin';
        Screen('TextSize',PTB.Window,round(instructionSize*.75));
        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
        getKey('b',PTB.kbNum);
        Screen(PTB.Window,'Flip');
        
        goTime = 0;
        
        getKey('b',PTB.kbNum);
        
        startTime = GetSecs;
        goTime=goTime+leadin;
        
        Screen(PTB.Window,'FillRect', PTB.screenColor);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime);
        
        
        for n=1:length(practice)
            
            fprintf(fileID,'%d\t',n);
            
            %%%%%% CONFIDENTS RATING %%%%%%%
            
            startSecs = GetSecs;
            KbQueueStart;%start recording button responces
            
            theData.onset.bet(n)=goTime;
            
            goTime=goTime+bettime;
            kbgoTime=goTime+2;%two extra seconds for collectiong button responces
            message=practice(n).name;
            Screen('TextSize',PTB.Window,textSize*3);
            DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor);
            message='Strong \nmemory';
            Screen('TextSize',PTB.Window,textSize);
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9,PTB.myRect(4)-textSize*3,PTB.textColor);
            message='Moderate \nmemory';
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 3,PTB.myRect(4)-textSize*3,PTB.textColor);
            message='Weak \nmemory';
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 5,PTB.myRect(4)-textSize*3,PTB.textColor);
            message='No \nmemory';
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 7,PTB.myRect(4)-textSize*3,PTB.textColor);
            Screen(PTB.Window,'Flip');
            
            WaitSecs('UntilTime',startTime+goTime);
            
            %%%%%%% DELAY %%%%%%%%%
            
            goTime=goTime+delay;
            Screen(PTB.Window, 'DrawTexture', fix);
            Screen(PTB.Window,'Flip');
            
            WaitSecs('UntilTime',startTime+kbgoTime);%wait for extra response time
            KbQueueStop; %stop recording button responces
            [~, firstPress]=KbQueueCheck;
            keypresses = find(firstPress);
            if ~isempty(keypresses)
                
                hold_time=firstPress(find(firstPress)) - startSecs;
                hold_press=keypresses;
                hold=cat(1,hold_time,hold_press);
                ordered=sortrows(hold',1);
                
                theData.all_resp.bet{n} =KbName(ordered(:,2));
                theData.all_respRT.bet{n} = ordered(:,1);
                
                
                if ~ismember(trigger_char,KbName(ordered(1,2)))
                    %strcmp(KbName(ordered(1,2)),trigger_char)
                    if iscell(theData.all_resp.bet{n})
                        theData.resp.bet{n}= theData.all_resp.bet{n}{1}(1);
                    else
                        theData.resp.bet{n}= theData.all_resp.bet{n}(1);
                    end
                    theData.respRT.bet(n) = theData.all_respRT.bet{n}(1);
                elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                    if iscell(theData.all_resp.bet{n})
                        theData.resp.bet{n}= theData.all_resp.bet{n}{2}(1);
                    else
                        theData.resp.bet{n}= theData.all_resp.bet{n}(2);
                    end
                    theData.respRT.bet(n) = theData.all_respRT.bet{n}(2);
                end
            end
            
            fprintf(fileID,'%d\t%s\t%d\t',theData.onset.bet(n),theData.resp.bet{n},theData.respRT.bet(n));
            
            WaitSecs('UntilTime',startTime+goTime);%wait for delay to finish
            
            %%%%%%% PROBE %%%%%%%%
            
            startSecs = GetSecs;
            KbQueueStart;
            
            theData.onset.probe(n)=goTime;
            
            goTime=goTime+probe;
            pic=practice(n).probe_image;
            Screen(PTB.Window, 'DrawTexture', pic,[],[RectLeft RectTop, RectRight, RectBottom]);
            message='Exact Same \npicture';
            Screen('TextSize',PTB.Window,textSize);
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9,PTB.myRect(4)-textSize*3,PTB.textColor);
            message='Similar \npicture';
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 3,PTB.myRect(4)-textSize*3,PTB.textColor);
            message='Very different \npicture';
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 5,PTB.myRect(4)-textSize*3,PTB.textColor);
            message='Do not \nknow';
            DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 7,PTB.myRect(4)-textSize*3,PTB.textColor);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
            
            %%%%%% INTER-TRIAL %%%%%%%
            
            if n~=length(practice)%no ITI for last trial
                goTime=goTime+readyforarrowsTime;
                Screen(PTB.Window,'FillRect', PTB.screenColor);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
                
                % doesnt stop collecting probe responce till arrows begin
                KbQueueStop;
                [~, firstPress]=KbQueueCheck;
                keypresses = find(firstPress);
                if ~isempty(keypresses)
                    
                    hold_time=firstPress(find(firstPress)) - startSecs;
                    hold_press=keypresses;
                    hold=cat(1,hold_time,hold_press);
                    ordered=sortrows(hold',1);
                    
                    theData.all_resp.probe{n} =KbName(ordered(:,2));
                    theData.all_respRT.probe{n} = ordered(:,1);
                    
                    
                    if ~ismember(trigger_char,KbName(ordered(1,2)))
                        if iscell(theData.all_resp.probe{n})
                            theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                        else
                            theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                        end
                        theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                    elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                        if iscell(theData.all_resp.probe{n})
                            theData.resp.probe{n}= theData.all_resp.probe{n}{2}(1);
                        else
                            theData.resp.probe{n}= theData.all_resp.probe{n}(2);
                        end
                        theData.respRT.probe(n) = theData.all_respRT.probe{n}(2);
                    end
                    
                end
                %                 keypresses = KbName(firstPress);
                %                 if ~isempty(keypresses)
                %
                %                     theData.all_resp.probe{n} = keypresses;
                %
                %                     if iscell(theData.all_resp.probe{n})
                %                         theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                %                     else
                %                         theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                %                     end
                %                     theData.all_respRT.probe{n} = firstPress(keypresses) - startSecs;
                %                     theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                %                 end
                
                fprintf(fileID,'%d\t%s\t%d\t%d\n',theData.onset.probe(n),theData.resp.probe{n},theData.respRT.probe(n),practice(n).correct_answer.number);
                
                for arrowcount = 1:4
                    
                    arrowset = Shuffle([1 2]);
                    arrow = arrowset(1);
                    
                    if mod(arrow,2)
                        arrowtype = 'left';
                        goTime = goTime + arrowTime;
                        Screen(PTB.Window, 'DrawTexture', L_arrow);
                        Screen(PTB.Window,'Flip');
                    else
                        arrowtype = 'right';
                        goTime = goTime + arrowTime;
                        Screen(PTB.Window, 'DrawTexture', R_arrow);
                        Screen(PTB.Window,'Flip');
                    end
                    
                    [keys RT] = recordKeys(startTime,goTime,PTB.boxNum);
                    eval(['theData.arrowresp' num2str(arrowcount) '{n} = keys;']);%record info about arrows responces
                    eval(['theData.arrowrespRT' num2str(arrowcount) '(n) = RT(1);']);
                    eval(['theData.arrowtype' num2str(arrowcount) '{n} = arrowtype;']);
                    WaitSecs('UntilTime',startTime+goTime);
                    
                    if arrowcount ~= 4
                        % Post-arrow fixation period
                        goTime = goTime + postarrowTime;
                        Screen(PTB.Window, 'DrawTexture', fix);
                        Screen(PTB.Window,'Flip');
                        [keys RT] = recordKeys(startTime,goTime,PTB.boxNum);
                    end
                    
                    if isempty(strmatch(keys, 'noanswer'))  %% if response made during post-arrow period, record it (overwriting previous)
                        eval(['theData.arrowresp' num2str(arrowcount) '{n} = keys;']);
                        eval(['theData.arrowrespRT' num2str(arrowcount) '(n) = RT(1) + arrowTime;']);
                        eval(['theData.arrowtype' num2str(arrowcount) '{n} = arrowtype;']);
                    end
                end
                
                goTime=goTime+readyfornexttrialTime;
                Screen(PTB.Window,'FillRect', PTB.screenColor);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
            else
                goTime=goTime+readyfornexttrialTime;
                Screen(PTB.Window,'FillRect', PTB.screenColor);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
                
                % doesnt stop collecting probe for extra second with blank screen for last trial
                KbQueueStop;
                [~, firstPress]=KbQueueCheck;
                keypresses = find(firstPress);
                if ~isempty(keypresses)
                    
                    hold_time=firstPress(find(firstPress)) - startSecs;
                    hold_press=keypresses;
                    hold=cat(1,hold_time,hold_press);
                    ordered=sortrows(hold',1);
                    
                    theData.all_resp.probe{n} =KbName(ordered(:,2));
                    theData.all_respRT.probe{n} = ordered(:,1);
                    
                    
                    if ~ismember(trigger_char,KbName(ordered(1,2)))
                        if iscell(theData.all_resp.probe{n})
                            theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                        else
                            theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                        end
                        theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                    elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                        if iscell(theData.all_resp.probe{n})
                            theData.resp.probe{n}= theData.all_resp.probe{n}{2}(1);
                        else
                            theData.resp.probe{n}= theData.all_resp.probe{n}(2);
                        end
                        theData.respRT.probe(n) = theData.all_respRT.probe{n}(2);
                    end
                end
                
                %                 keypresses = KbName(firstPress);
                %                 if ~isempty(keypresses)
                %
                %                     theData.all_resp.probe{n} = keypresses;
                %
                %                     if iscell(theData.all_resp.probe{n})
                %                         theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                %                     else
                %                         theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                %                     end
                %                     theData.all_respRT.probe{n} = firstPress(find(firstPress)) - startSecs;
                %                     theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                %                 end
                
                fprintf(fileID,'%d\t%s\t%d\t%d\n',theData.onset.probe(n),theData.resp.probe{n},theData.respRT.probe(n),practice(n).correct_answer.number);
                
            end
            
        end
        
        message='Do you have any questions after the practice?  \nNow we will move onto the task. \n\n\n\nPress ''b'' to finish';
        Screen('TextSize',PTB.Window,textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        savefile=sprintf('%s_practice_data_%s.mat',subID,date);%the name of the file
        cd ../data;
        save(savefile,'theData');%saves data in the data dir
        
        cd(script_dirct);%has to move back to scriprs dir to get out using getKey
        getKey('b',PTB.kbNum);
        clear Screen;
        
    case 3 %test phase
        
        message='loading images...';
        Screen('TextSize',PTB.Window,textSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        Screen(PTB.Window,'Flip');
        
        theData.trial=trial;%saves the trial info in theData
        
        if PTB.block_start==1
            savefiletx=sprintf('%s_data_%s_%s.txt',subID,date,datestr(now,13));
        else
            savefiletx=sprintf('%s_data_%s_startblock_%d_%s.txt',subID,date,PTB.block_start,datestr(now,13));
        end
        
        fileID = fopen(savefiletx,'a');
        fprintf(fileID,'MM data file for %s at %s starting with block %d\nBlock\tTrial\tBet_onset\tBet_Resp\tBet_RT\tProbe_onset\tProbe_Resp\tProbe_RT\tCorrect\n',subID,datestr(now),PTB.block_start);
        
        %populates theData
        for n=1:length(trial)
            theData.resp.bet{n}= 'noanswer';
            theData.resp.probe{n}= 'noanswer';
            theData.all_resp.bet{n} = 'noanswer';
            theData.all_resp.probe{n} = 'noanswer';
            theData.all_respRT.bet{n} = 'noanswer';
            theData.all_respRT.probe{n} = 'noanswer';
            theData.respRT.bet(n) = 0;
            theData.respRT.probe(n) = 0;
            theData.onset.bet(n) = 0;
            theData.onset.probe(n) = 0;
        end
        
        cd ../stims;
        for n=1:length(trial)
            picname=trial(n).probe_name;
            pic=imread(char(picname),'jpg');
            trial(n).probe_image=Screen(PTB.Window,'MakeTexture',pic);
        end
        
        cd(script_dirct);
        
        message=['For each trial you will see a name that you learned before and will make a judgment about your memory '...
            'for the paired image, then there will be a delay, where you should picture the paired image, followed by an '...
            'image where you will indicate if it is an exact match, similar image, very different image, or dont know then '...
            'a new trial will start.  You will have only two seconds to make your responses so be sure to make response in '...
            'that time.\n\n This task will be broken up into eight blocks, each about six minutes long, with breaks to '...
            'rest in between. Are you ready?'];
        Screen('TextSize',PTB.Window,instructionSize);
        DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
        
        switch PTB.scan
            case 1
                message_add='Experimentor press ''b'' to wait for trigger';
                Screen('TextSize',PTB.Window,round(instructionSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
                Screen(PTB.Window,'FillRect', PTB.screenColor);
                getKey('b',PTB.kbNum);
                %tic%if pressed with start of the scan, will give time delay before first TR
                Screen(PTB.Window,'Flip');
            case 2
                message_add='Press ''b'' to begin';
                Screen('TextSize',PTB.Window,round(instructionSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
            case 3
                message_add='Experimentor press ''b'' to begin';
                Screen('TextSize',PTB.Window,round(instructionSize*.75));
                DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                Screen(PTB.Window,'Flip');
        end
        
        switch  PTB.scan
            case 1
                getKey(trigger_char,PTB.boxNum);
                WaitSecs(0.001);
                %less_delay=toc;
                message='Waiting for trigger...';
                Screen('TextSize',PTB.Window,instructionSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                Screen(PTB.Window,'Flip');
            case {2,3}
                getKey('b',PTB.kbNum);
        end
        
        
        for m = PTB.block_start:PTB.blocks %for each block
            
            goTime = 0;%starts go time again
            
            startTime = GetSecs;
            %             if PTB.scan == 1
            %                 leadin=leadin-less_delay;
            %             end
            goTime=goTime+leadin;
            
            Screen(PTB.Window,'FillRect', PTB.screenColor);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
            
            
            for k=1:PTB.blocks_stim %for each trial in each block
                
                n=((m-1)*PTB.blocks_stim)+k;%trial to call given the block and trial within the block
                
                if n > length(trial) %This should end the stim presentation if the last block is shorter than the rest. This wont be as pretty, it will have an iti at the end when the others don't
                    %blank screen lead out time before ending
                    goTime=goTime+leadout;
                    Screen(PTB.Window,'FillRect', PTB.screenColor);
                    Screen(PTB.Window,'Flip');
                    WaitSecs('UntilTime',startTime+goTime);
                    break
                end
                
                fprintf(fileID,'%d\t%d\t',theData.trial(n).block,n);
                
                %%%%%% CONFIDENTS RATING %%%%%%%
                
                startSecs = GetSecs;
                KbQueueStart;
                
                theData.onset.bet(n)=goTime;
                
                goTime=goTime+bettime;
                kbgoTime=goTime+2;%two extra seconds for collectiong button responces
                message=trial(n).name;
                Screen('TextSize',PTB.Window,textSize*3);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor);
                message='Strong \nmemory';
                Screen('TextSize',PTB.Window,textSize);
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9,PTB.myRect(4)-textSize*3,PTB.textColor);
                message='Moderate \nmemory';
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 3,PTB.myRect(4)-textSize*3,PTB.textColor);
                message='Weak \nmemory';
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 5,PTB.myRect(4)-textSize*3,PTB.textColor);
                message='No \nmemory';
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 7,PTB.myRect(4)-textSize*3,PTB.textColor);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
                
                %%%%%%% DELAY %%%%%%%%%
                
                goTime=goTime+delay;
                Screen(PTB.Window, 'DrawTexture', fix);
                Screen(PTB.Window,'Flip');
                
                WaitSecs('UntilTime',startTime+kbgoTime);%wait for extra response time
                KbQueueStop;
                [~, firstPress]=KbQueueCheck;
                keypresses = find(firstPress);
                if ~isempty(keypresses)
                    
                    hold_time=firstPress(find(firstPress)) - startSecs;
                    hold_press=keypresses;
                    hold=cat(1,hold_time,hold_press);
                    ordered=sortrows(hold',1);
                    
                    theData.all_resp.bet{n} =KbName(ordered(:,2));
                    theData.all_respRT.bet{n} = ordered(:,1);
                    
                    
                    if ~ismember(trigger_char,KbName(ordered(1,2)))
                        if iscell(theData.all_resp.bet{n})
                            theData.resp.bet{n}= theData.all_resp.bet{n}{1}(1);
                        else
                            theData.resp.bet{n}= theData.all_resp.bet{n}(1);
                        end
                        theData.respRT.bet(n) = theData.all_respRT.bet{n}(1);
                    elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                        if iscell(theData.all_resp.bet{n})
                            theData.resp.bet{n}= theData.all_resp.bet{n}{2}(1);
                        else
                            theData.resp.bet{n}= theData.all_resp.bet{n}(2);
                        end
                        theData.respRT.bet(n) = theData.all_respRT.bet{n}(2);
                    end
                end
                
                %                 keypresses = KbName(firstPress);
                %                 if ~isempty(keypresses)
                %
                %                     theData.all_resp.bet{n} = keypresses;
                %
                %                     if iscell(theData.all_resp.bet{n})
                %                         theData.resp.bet{n}= theData.all_resp.bet{n}{1}(1);
                %                     else
                %                         theData.resp.bet{n}= theData.all_resp.bet{n}(1);
                %                     end
                %                     theData.all_respRT.bet{n} = firstPress(find(firstPress)) - startSecs;
                %                     theData.respRT.bet(n) = theData.all_respRT.bet{n}(1);
                %                 end
                
                fprintf(fileID,'%d\t%s\t%d\t',theData.onset.bet(n),theData.resp.bet{n},theData.respRT.bet(n));
                
                WaitSecs('UntilTime',startTime+goTime);%wait for rest of delay time
                
                %%%%%%% PROBE %%%%%%%%
                
                startSecs = GetSecs;
                KbQueueStart;
                
                theData.onset.probe(n)=goTime;
                
                goTime=goTime+probe;
                
                pic=trial(n).probe_image;
                
                Screen(PTB.Window, 'DrawTexture', pic,[],[RectLeft RectTop, RectRight, RectBottom]);
                message='Exact Same \npicture';
                Screen('TextSize',PTB.Window,textSize);
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9,PTB.myRect(4)-textSize*3,PTB.textColor);
                message='Similar \npicture';
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 3,PTB.myRect(4)-textSize*3,PTB.textColor);
                message='Very different \npicture';
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 5,PTB.myRect(4)-textSize*3,PTB.textColor);
                message='Do not \nknow';
                DrawFormattedText(PTB.Window,message,PTB.myRect(3)/9 * 7,PTB.myRect(4)-textSize*3,PTB.textColor);
                Screen(PTB.Window,'Flip');
                WaitSecs('UntilTime',startTime+goTime);
                
                
                
                %%%%%% INTER-TRIAL %%%%%%%
                
                
                if n~=((m-1)*PTB.blocks_stim)+PTB.blocks_stim %no ITI for last trial
                    
                    goTime=goTime+readyforarrowsTime;
                    Screen(PTB.Window,'FillRect', PTB.screenColor);
                    Screen(PTB.Window,'Flip');
                    WaitSecs('UntilTime',startTime+goTime);
                    
                    % doesnt stop collecting probe responce till arrows
                    % begin - extra 1 second
                    KbQueueStop;
                    [~, firstPress]=KbQueueCheck;
                    keypresses = find(firstPress);
                    if ~isempty(keypresses)
                        
                        hold_time=firstPress(find(firstPress)) - startSecs;
                        hold_press=keypresses;
                        hold=cat(1,hold_time,hold_press);
                        ordered=sortrows(hold',1);
                        
                        theData.all_resp.probe{n} =KbName(ordered(:,2));
                        theData.all_respRT.probe{n} = ordered(:,1);
                        
                        
                        if ~ismember(trigger_char,KbName(ordered(1,2)))
                            if iscell(theData.all_resp.probe{n})
                                theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                            else
                                theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                            end
                            theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                        elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                            if iscell(theData.all_resp.probe{n})
                                theData.resp.probe{n}= theData.all_resp.probe{n}{2}(1);
                            else
                                theData.resp.probe{n}= theData.all_resp.probe{n}(2);
                            end
                            theData.respRT.probe(n) = theData.all_respRT.probe{n}(2);
                        end
                        
                    end
                    %                     keypresses = KbName(firstPress);
                    %                     if ~isempty(keypresses)
                    %
                    %                         theData.all_resp.probe{n} = keypresses;
                    %
                    %                         if iscell(theData.all_resp.probe{n})
                    %                             theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                    %                         else
                    %                             theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                    %                         end
                    %                         theData.all_respRT.probe{n} = firstPress(find(firstPress)) - startSecs;
                    %                         theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                    %                     end
                    
                    fprintf(fileID,'%d\t%s\t%d\t%d\n',theData.onset.probe(n),theData.resp.probe{n},theData.respRT.probe(n),trial(n).correct_answer.number);
                    
                    for arrowcount = 1:4
                        
                        arrowset = Shuffle([1 2]);
                        arrow = arrowset(1);
                        
                        if mod(arrow,2)
                            arrowtype = 'left';
                            goTime = goTime + arrowTime;
                            Screen(PTB.Window, 'DrawTexture', L_arrow);
                            Screen(PTB.Window,'Flip');
                        else
                            arrowtype = 'right';
                            goTime = goTime + arrowTime;
                            Screen(PTB.Window, 'DrawTexture', R_arrow);
                            Screen(PTB.Window,'Flip');
                        end
                        
                        [keys RT] = recordKeys(startTime,goTime,PTB.boxNum);
                        eval(['theData.arrowresp' num2str(arrowcount) '{n} = keys;']);
                        eval(['theData.arrowrespRT' num2str(arrowcount) '(n) = RT(1);']);
                        eval(['theData.arrowtype' num2str(arrowcount) '{n} = arrowtype;']);
                        WaitSecs('UntilTime',startTime+goTime);
                        
                        if arrowcount ~= 4
                            % Post-arrow fixation period
                            goTime = goTime + postarrowTime;
                            Screen(PTB.Window, 'DrawTexture', fix);
                            Screen(PTB.Window,'Flip');
                            [keys RT] = recordKeys(startTime,goTime,PTB.boxNum);
                        end
                        
                        if isempty(strmatch(keys, 'noanswer'))  %% if response made during post-arrow period, record it (overwriting previous)
                            eval(['theData.arrowresp' num2str(arrowcount) '{n} = keys;']);
                            eval(['theData.arrowrespRT' num2str(arrowcount) '(n) = RT(1) + arrowTime;']);
                            eval(['theData.arrowtype' num2str(arrowcount) '{n} = arrowtype;']);
                        end
                    end
                    
                    goTime=goTime+readyfornexttrialTime;
                    Screen(PTB.Window,'FillRect', PTB.screenColor);
                    Screen(PTB.Window,'Flip');
                    WaitSecs('UntilTime',startTime+goTime);
                else
                    %blank screen at the end of the end of the block
                    kbgoTime=goTime+readyfornexttrialTime;%same extra one second collection period for last trail
                    goTime=goTime+leadout;
                    Screen(PTB.Window,'FillRect', PTB.screenColor);
                    Screen(PTB.Window,'Flip');
                    
                    % doesnt stop collecting probe for extra second with blank screen for last trial
                    WaitSecs('UntilTime',startTime+kbgoTime);
                    KbQueueStop;
                    [~, firstPress]=KbQueueCheck;
                    keypresses = find(firstPress);
                    if ~isempty(keypresses)
                        
                        hold_time=firstPress(find(firstPress)) - startSecs;
                        hold_press=keypresses;
                        hold=cat(1,hold_time,hold_press);
                        ordered=sortrows(hold',1);
                        
                        theData.all_resp.probe{n} =KbName(ordered(:,2));
                        theData.all_respRT.probe{n} = ordered(:,1);
                        
                        
                        if ~ismember(trigger_char,KbName(ordered(1,2)))
                            if iscell(theData.all_resp.probe{n})
                                theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                            else
                                theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                            end
                            theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                        elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                            if iscell(theData.all_resp.probe{n})
                                theData.resp.probe{n}= theData.all_resp.probe{n}{2}(1);
                            else
                                theData.resp.probe{n}= theData.all_resp.probe{n}(2);
                            end
                            theData.respRT.probe(n) = theData.all_respRT.probe{n}(2);
                        end
                        
                    end
                    
                    %                     keypresses = KbName(firstPress);
                    %                     if ~isempty(keypresses)
                    %
                    %                         theData.all_resp.probe{n} = keypresses;
                    %
                    %                         if iscell(theData.all_resp.probe{n})
                    %                             theData.resp.probe{n}= theData.all_resp.probe{n}{1}(1);
                    %                         else
                    %                             theData.resp.probe{n}= theData.all_resp.probe{n}(1);
                    %                         end
                    %                         theData.all_respRT.probe{n} = firstPress(find(firstPress)) - startSecs;
                    %                         theData.respRT.probe(n) = theData.all_respRT.probe{n}(1);
                    %
                    %                     end
                    
                    fprintf(fileID,'%d\t%s\t%d\t%d\n',theData.onset.probe(n),theData.resp.probe{n},theData.respRT.probe(n),trial(n).correct_answer.number);
                    
                    WaitSecs('UntilTime',startTime+goTime);%wait rest of lead out time
                    
                end
                
                Screen('Close',pic);%closes texture after each trial
                
                %saves at the end of each block
                savefile=sprintf('%s_data_block%d_%s.mat',subID,m,date);
                cd ../data;
                save(savefile,'theData');
                cd(script_dirct);
                
            end
            if m==PTB.blocks
                if PTB.localizer==1
                    message='Congratulations, you have completed the task.  \nThank you very much!\n\n\n\n\nExperimentor press ''b'' to move on';
                else
                    message='Congratulations, you have completed the task.  \nThank you very much!';
                end
                Screen('TextSize',PTB.Window,textSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                Screen(PTB.Window,'Flip');
            else %break between blocks,
                message='Break \n Please take a minute to rest and relax';
                Screen('TextSize',PTB.Window,textSize);
                DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
                switch PTB.scan
                    case 1
                        message_add='Experimentor press ''b'' to wait for trigger';
                        Screen('TextSize',PTB.Window,textSize);
                        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                        Screen(PTB.Window,'Flip');
                        Screen(PTB.Window,'FillRect', PTB.screenColor);
                        getKey('b',PTB.kbNum);
                        %tic%if pressed with start of the scan, will give time delay before first TR
                        Screen(PTB.Window,'Flip');
                    case 2
                        message_add='Press ''b'' to begin';
                        Screen('TextSize',PTB.Window,textSize);
                        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                        Screen(PTB.Window,'Flip');
                    case 3
                        message_add='Experimentor press ''b'' to begin';
                        Screen('TextSize',PTB.Window,textSize);
                        DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
                        Screen(PTB.Window,'Flip');
                end
                
                switch  PTB.scan
                    case 1
                        getKey(trigger_char,PTB.boxNum);
                        WaitSecs(0.001);
                        %less_delay=toc;
                    case {2,3}
                        getKey('b',PTB.kbNum);
                end
                
            end
        end
        
        if PTB.block_start==1
            savefile=sprintf('%s_data_%s_final.mat',subID,date);
            cd ../data;
            save(savefile,'theData');
        else
            savefile=sprintf('%s_data_%s_startblock_%d_final.mat',subID,date,PTB.block_start);
            cd ../data;
            save(savefile,'theData');
        end
        
        cd(script_dirct);
        
        if PTB.localizer==1
            getKey('b',PTB.kbNum);
        else
            pause(5);%wait 5 second before clearing screen
            clear Screen;
        end
        
    case 4
        PTB.localizer=1;
end

if PTB.localizer==1
    
    message='loading images...'; %screen says loading images if it takes a while to make all the textures
    Screen('TextSize',PTB.Window,textSize);
    DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
    Screen(PTB.Window,'Flip');
    
    cd ../stims;
    
    for n=1:length(theLocalizer.info) %pre-makes textures for trials
        if ~isempty(theLocalizer.info(n).stim_name)
            picname=theLocalizer.info(n).stim_name;
            pic=imread(char(picname),'jpg');
            theLocalizer.info(n).stim_image=Screen(PTB.Window,'MakeTexture',pic);
        else
            theLocalizer.info(n).stim_image=fix;
        end
    end
    
    cd(script_dirct);
    
    for n=1:length(theLocalizer.info)
        theLocalizer.resp{n}= 'noanswer';
        theLocalizer.pressed(n)=false;
        theLocalizer.all_resp{n} = 'noanswer';
        theLocalizer.all_respRT{n} = 'noanswer';
        theLocalizer.respRT(n) = 0;
        theLocalizer.repeat(n)=false;
        theLocalizer.onset(n) = 0;
    end
    for n=1:length(theLocalizer.info)
        if theLocalizer.info(n).will_repeat == 2
            theLocalizer.repeat(n+1)=true;
        end
    end
    
    savefiletx=sprintf('%s_localizer_%s_%s.txt',subID,date,datestr(now,13));
    fileID = fopen(savefiletx,'a');
    fprintf(fileID,'MM localizer data file for %s at %s \nTrial\tOnset\tStim_Cat\tRepeat\tPressed\tResp\tRT\n',subID,datestr(now));
    
    message=['You will see a series of images, each presented for one second.  Your job is to press the first button '...
        'when an image is repeated, shown twice in a row.  Interspersed during the scan will be brief periods where only a '...
        'fixation cross will be on the screen. Are you ready?'];
    Screen('TextSize',PTB.Window,instructionSize);
    DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
    
    switch PTB.scan
        case 1
            message_add='Experimentor press ''b'' to wait for trigger';
            Screen('TextSize',PTB.Window,round(instructionSize*.75));
            DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
            Screen(PTB.Window,'Flip');
            Screen(PTB.Window,'FillRect', PTB.screenColor);
            getKey('b',PTB.kbNum);
            Screen(PTB.Window,'Flip');
        case 2
            message_add='Press ''b'' to begin';
            Screen('TextSize',PTB.Window,round(instructionSize*.75));
            DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
            Screen(PTB.Window,'Flip');
        case 3
            message_add='Experimentor press ''b'' to begin';
            Screen('TextSize',PTB.Window,round(instructionSize*.75));
            DrawFormattedText(PTB.Window,message_add,'center',PTB.myRect(4)-textSize*2,PTB.textColor);
            Screen(PTB.Window,'Flip');
    end
    
    switch  PTB.scan
        case 1
            getKey(trigger_char,PTB.boxNum);
            WaitSecs(0.001);
            message='Waiting for trigger...';
            Screen('TextSize',PTB.Window,instructionSize);
            DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
            Screen(PTB.Window,'Flip');
        case {2,3}
            getKey('b',PTB.kbNum);
    end
    
    
    goTime = 0;%starts go time again
    
    startTime = GetSecs;
    goTime=goTime+leadin;
    
    Screen(PTB.Window,'FillRect', PTB.screenColor);
    Screen(PTB.Window,'Flip');
    WaitSecs('UntilTime',startTime+goTime);
    
    
    
    for n=1:length(theLocalizer.info)
        
        fprintf(fileID,'%d\t',n);
        
        startSecs = GetSecs;
        KbQueueStart;
        theLocalizer.onset(n)=goTime;
        goTime=goTime+imagetime;
        
        pic=theLocalizer.info(n).stim_image;
        
        Screen(PTB.Window, 'DrawTexture', pic,[],[RectLeft RectTop, RectRight, RectBottom]);
        Screen(PTB.Window,'Flip');
        WaitSecs('UntilTime',startTime+goTime);
        %fixation
        if n~=length(theLocalizer.info)
            goTime=goTime+offtime;
            
            Screen(PTB.Window, 'DrawTexture', fix,[],[RectLeft RectTop, RectRight, RectBottom]);
            Screen(PTB.Window,'Flip');
            WaitSecs('UntilTime',startTime+goTime);
        else %else leadout for last trial
            goTime=goTime+leadout_mvpa;
            Screen(PTB.Window,'FillRect', PTB.screenColor);
            Screen(PTB.Window,'Flip');
        end
        KbQueueStop;
        [~, firstPress]=KbQueueCheck;
        keypresses = find(firstPress);
        if ~isempty(keypresses)
            
            hold_time=firstPress(find(firstPress)) - startSecs;
            hold_press=keypresses;
            hold=cat(1,hold_time,hold_press);
            ordered=sortrows(hold',1);
            
            theLocalizer.all_resp{n} =KbName(ordered(:,2));
            theLocalizer.all_respRT{n} = ordered(:,1);
            
            
            if ~ismember(trigger_char,KbName(ordered(1,2)))
                if iscell(theLocalizer.all_resp{n})
                    theLocalizer.resp{n}= theLocalizer.all_resp{n}{1}(1);
                else
                    theLocalizer.resp{n}= theLocalizer.all_resp{n}(1);
                end
                theLocalizer.respRT(n) = theLocalizer.all_respRT{n}(1);
                theLocalizer.pressed(n)=true;
            elseif length(ordered(:,2))>1   %~isempty(ordered(2,1))
                if iscell(theLocalizer.all_resp{n})
                    theLocalizer.resp{n}= theLocalizer.all_resp{n}{2}(1);
                else
                    theLocalizer.resp{n}= theLocalizer.all_resp{n}(2);
                end
                theLocalizer.respRT(n) = theLocalizer.all_respRT{n}(2);
                theLocalizer.pressed(n)=true;
            end
        end
        fprintf(fileID,'%d\t%d\t%d\t%d\t%s\t%d\n',theLocalizer.onset(n),theLocalizer.info(n).stim_catagory.number,theLocalizer.repeat(n),theLocalizer.pressed(n),...
            theLocalizer.resp{n},theLocalizer.respRT(n));
    end
    
    goTime=goTime+leadout;
    Screen(PTB.Window,'FillRect', PTB.screenColor);
    Screen(PTB.Window,'Flip');
    WaitSecs('UntilTime',startTime+goTime);
    
    message='Congratulations, you have completed the experiment.  \nThank you very much!';
    Screen('TextSize',PTB.Window,textSize);
    DrawFormattedText(PTB.Window,message,'center','center',PTB.textColor,wrap,[],[],2);
    Screen(PTB.Window,'Flip');
    
    savefile=sprintf('%s_localizer_%s.mat',subID,date);
    cd ../data;
    save(savefile,'theLocalizer');
    
    pause(5);%wait 5 second before clearing screen
    clear Screen;
end

ShowCursor;
Screen('Resolution', PTB.screenNumber, [old.width], [old.height]);

end







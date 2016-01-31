function Seq_listmake

answer=inputdlg({'Subject number:','Number of trials'},'Counterbalance list inputs',1,{'701','120'});
SubID=answer{1};
num_trials=str2double(answer{2});

num_blocks=4;
trials_block=num_trials/num_blocks;

script_path=which('Seq_listmake.m');
script_dirct=fileparts(script_path);
base_dir=fileparts(script_dirct);

repeats=num_trials/24;
if rem(num_trials,24)>0
    error('Seq_listmake:argChk','Number of trials needs to be a factor of 24')
end

RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock))); %Resets the random number generator, otherwise would randomize the same every time matlab restarts

skeletona=zeros(24,2);

skeletona(1:10,1)=2;%mm
skeletona(11:18,1)=1;%repeat
skeletona(19:24,1)=3;%new
skeletona([1:5,11:14],2)=1;%old_bg
skeletona([6:10,15:18],2)=2;%new_bg
skeletona(19:24,2)=3;%nan

bg_every_other=repmat(1:2,1,12);

skeleton=zeros(num_trials,3);

pointer=1;
for n=1:repeats
    skeleton(pointer:pointer+23,1:2)=skeletona;
    skeleton(pointer:pointer+23,3)=bg_every_other+((n-1)*2);
    pointer=pointer+24;
end

new_index=find(skeleton(:,1)==3)';
mm_index=find(skeleton(:,1)==2)';
match_index=find(skeleton(:,1)==1)';
%needs orders (2/3 swap, or 3/4th swap)
swap(1:2:length(mm_index)-1)=1;%all 3/4

swap(2:2:length(mm_index))=1;
skeleton(mm_index,4)=swap;

stim_ref=randperm(num_trials*4);

stim_test=1:num_trials*4;

%% to properly couterbalance for the scanner (almost equal number of
%% conditions per block
num_n_block=floor(length(new_index)/num_blocks);
fix_n=[num_n_block num_n_block+1 num_n_block num_n_block+1];%HARD CODED!!!
num_m_block=floor(length(match_index)/num_blocks);
fix_m=[num_m_block num_m_block num_m_block num_m_block];%HARD CODED!!!
num_mm_block=floor(length(mm_index)/num_blocks);
fix_mm=[num_mm_block+1 num_mm_block num_mm_block+1 num_mm_block];%HARD CODED!!!

rand_list_n=randperm(length(new_index));
rand_list_m=randperm(length(match_index));
rand_list_mm=randperm(length(mm_index));
rand_list=[];
for n=1:num_blocks
    holder_rand=randperm(trials_block);
    rand_list_holder=[new_index(rand_list_n(1:fix_n(n))) match_index(rand_list_m(1:fix_m(n))) mm_index(rand_list_mm(1:fix_mm(n)))];
    rand_list_n(1:fix_n(n))=[]; rand_list_m(1:fix_m(n))=[]; rand_list_mm(1:fix_mm(n))=[];
    rand_list=[rand_list rand_list_holder(holder_rand)];
end
counterlist.scan_order=rand_list;
counterlist.test_order=randperm(num_trials);

called_list=[];

%% BG SWAP Setup
swap_bg{1}=2:6;
swap_bg{2}=3:7;
swap_bg{3}=4:8;
swap_bg{4}=5:9;
swap_bg{5}=6:10;
swap_bg{6}=[7:10 1];
swap_bg{7}=[8:10 1:2];
swap_bg{8}=[9:10 1:3];
swap_bg{9}=[10 1:4];
swap_bg{10}=1:5;

new_stims=[];

learn_num=1;
for n=1:num_trials

    counterlist.trial_info(n).scan.images=stim_ref(1:4);
    stim_ref(1:4)=[];
    
    counterlist.trial_info(n).scan.background=skeleton(n,3);
    counterlist.trial_info(n).test.bg_images=counterlist.trial_info(n).scan.background;
    
    switch skeleton(n,1)
        case 1
            counterlist.trial_info(n).trial_type.name='repeat';
            counterlist.trial_info(n).trial_type.number=1;
            counterlist.trial_info(n).pre.images=counterlist.trial_info(n).scan.images;
            counterlist.learn_trials(learn_num)=n;
            learn_num=learn_num+1;
            switch skeleton(n,2)
                case 1
                    counterlist.trial_info(n).bg_type.name='repeat';
                    counterlist.trial_info(n).bg_type.number=1;
                    counterlist.trial_info(n).pre.background=counterlist.trial_info(n).scan.background;
                case 2
                    counterlist.trial_info(n).bg_type.name='mismatch';
                    counterlist.trial_info(n).bg_type.number=2;

                    counterlist.trial_info(n).pre.background=swap_bg{counterlist.trial_info(n).scan.background}(1);
                    swap_bg{counterlist.trial_info(n).scan.background}(1)=[];
                    
                    counterlist.trial_info(n).test.bg_images=[counterlist.trial_info(n).test.bg_images counterlist.trial_info(n).pre.background];
            end
        case 2
            counterlist.trial_info(n).trial_type.name='mismatch';
            counterlist.trial_info(n).trial_type.number=2;
            switch skeleton(n,4)
                case 1
                    counterlist.trial_info(n).pre.images=counterlist.trial_info(n).scan.images([1 2 4 3]);                                        
                case 2
                    counterlist.trial_info(n).pre.images=counterlist.trial_info(n).scan.images([1 3 2 4]);
            end
            counterlist.learn_trials(learn_num)=n;
            learn_num=learn_num+1;
            switch skeleton(n,2)
                case 1
                    counterlist.trial_info(n).bg_type.name='repeat';
                    counterlist.trial_info(n).bg_type.number=1;
                    counterlist.trial_info(n).pre.background=counterlist.trial_info(n).scan.background;
                case 2
                    counterlist.trial_info(n).bg_type.name='mismatch';
                    counterlist.trial_info(n).bg_type.number=2;
                    counterlist.trial_info(n).pre.background=swap_bg{counterlist.trial_info(n).scan.background}(1);
                    swap_bg{counterlist.trial_info(n).scan.background}(1)=[];
            end
        case 3
            counterlist.trial_info(n).trial_type.name='new';
            counterlist.trial_info(n).trial_type.number=3;
            counterlist.trial_info(n).bg_type.name='new';
            counterlist.trial_info(n).bg_type.number=3;
            new_stims=[new_stims counterlist.trial_info(n).scan.images];
    end
    
    
    not_use_test=[called_list counterlist.trial_info(n).scan.images];
    
    can_use=setdiff(stim_test,not_use_test);
    
    choice_1=can_use(randi(length(can_use),1));
    called_list=[called_list choice_1];
    %choice_2=can_use(randi(length(can_use),1));
    %called_list=[called_list choice_2];
    
    counterlist.trial_info(n).test.images=[counterlist.trial_info(n).scan.images choice_1];
    %counterlist.trial_info(n).test.images=[counterlist.trial_info(n).scan.images choice_1 choice_2];
        
    bg_img_test=randperm(10);
    [~,already]=ismember(bg_img_test,counterlist.trial_info(n).test.bg_images);
    bg_img_test(find(already))=[];
    counterlist.trial_info(n).test.bg_images=[counterlist.trial_info(n).test.bg_images bg_img_test(1:5-length(counterlist.trial_info(n).test.bg_images))];
    
end
%% Pre-exposure/ novelity task
pre_ex_latin=[1 2 3 2 1 2 1 3 2 1 3 1 2 1 2 3 2 1 3 1 2 1 2 3 1 2 3 2 1 2 1];
pre_expose_order=new_stims(randperm(length(new_stims)));
pre_per_block=length(new_stims)/sum(pre_ex_latin==1);
for n=1:length(pre_ex_latin)
    counterlist.pre_info.block(n).repeat_type.number=pre_ex_latin(n);
    repeat=randi([3 pre_per_block],1);
    counterlist.pre_info.block(n).repeat=repeat;
    switch pre_ex_latin(n)
        case 1
            counterlist.pre_info.block(n).repeat_type.name='novel';
            new_order=pre_expose_order(1:pre_per_block);pre_expose_order(1:pre_per_block)=[];
            new_order_a=new_order(1:repeat);new_order_b=new_order(repeat+1:pre_per_block);
            new_order=[new_order_a new_order(repeat) new_order_b];
            counterlist.pre_info.block(n).images=new_order;
        case 2
            counterlist.pre_info.block(n).repeat_type.name='repeat';
            repeat_order=randperm(pre_per_block);
            repeat_order_a=repeat_order(1:repeat);repeat_order_b=repeat_order(repeat+1:pre_per_block);
            repeat_order=[repeat_order_a repeat_order(repeat) repeat_order_b];
            counterlist.pre_info.block(n).images=repeat_order;
        case 3
            counterlist.pre_info.block(n).repeat_type.name='blank';
            counterlist.pre_info.block(n).images=ones(1,pre_per_block+1);
    end
end
%% Populate actual file names
stims_list=[];%change for actual name
bg_list=[];
repeats_list=[];
load([base_dir '/stims/stims_names.mat'])%change for actual reference file
load([base_dir '/stims/bg_names.mat'])
load([base_dir '/stims/repeats_names.mat'])

for n=1:num_trials
    for m=1:4
        counterlist.trial_info(n).scan.image_names{m}=stims_list(counterlist.trial_info(n).scan.images(m));
    end
    for m=1:5
        counterlist.trial_info(n).test.image_names{m}=stims_list(counterlist.trial_info(n).test.images(m));
    end
    for m=1:5
        counterlist.trial_info(n).test.bg_images_names{m}=bg_list(counterlist.trial_info(n).test.bg_images(m));
    end
    counterlist.trial_info(n).scan.bg_name=bg_list(counterlist.trial_info(n).scan.background);
    if ismember(n,counterlist.learn_trials)
        for m=1:4
            counterlist.trial_info(n).pre.image_names{m}=stims_list(counterlist.trial_info(n).pre.images(m));
        end
    counterlist.trial_info(n).pre.bg_name=bg_list(counterlist.trial_info(n).pre.background);
    end
end

for n=1:length(pre_ex_latin)
    for m=1:pre_per_block
        trial_ref=((n-1)*pre_per_block)+m;
        counterlist.pre_trials(trial_ref).block=n;
        switch counterlist.pre_info.block(n).repeat_type.name
            case 'novel'
                counterlist.pre_trials(trial_ref).image=stims_list(counterlist.pre_info.block(n).images(m));
            case 'repeat'
                counterlist.pre_trials(trial_ref).image=repeats_list(counterlist.pre_info.block(n).images(m));
            case 'blank'
                counterlist.pre_trials(trial_ref).image='fix.jpg';
        end
        counterlist.pre_trials(trial_ref).repeat_type.name=counterlist.pre_info.block(n).repeat_type.name;
        counterlist.pre_trials(trial_ref).repeat_type.number=counterlist.pre_info.block(n).repeat_type.number;
        if m==counterlist.pre_info.block(n).repeat
            counterlist.pre_trials(trial_ref).repeat.name='repeat';
            counterlist.pre_trials(trial_ref).repeat.number=1;
        else
            counterlist.pre_trials(trial_ref).repeat.name='non';
            counterlist.pre_trials(trial_ref).repeat.number=0;
        end
    end
end
savefile=sprintf('%s/lists/%s_list_%s_%s.mat',base_dir,SubID,date,datestr(now,13));
save(savefile,'counterlist')

end
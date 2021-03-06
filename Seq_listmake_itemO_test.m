function Seq_listmake_itemO

answer=inputdlg({'Subject number:','Number of trials'},'Counterbalance list inputs',1,{'601','95'});
SubID=answer{1};
num_trials=str2double(answer{2});

num_blocks=5;
trials_block=num_trials/num_blocks;

script_path=which('Seq_listmake_itemO.m');
script_dirct=fileparts(script_path);
base_dir=fileparts(script_dirct);

base_con=19;

repeats=num_trials/base_con;
if rem(num_trials,base_con)>0
    error('Seq_listmake:argChk','Number of trials needs to be a factor of %d',base_con)
end

RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock))); %Resets the random number generator, otherwise would randomize the same every time matlab restarts

skeletona=zeros(base_con,1);

skeletona(1:5,1)=2;%repeat
skeletona(6:12,1)=1;%mm
skeletona(13:19,1)=3;%scramble

pos_every_other_b=[zeros(1,5) repmat(3:4,1,7)];
pos_every_other_a=[zeros(1,5) repmat(4:-1:3,1,7)];

skeleton=zeros(num_trials,2);

pointer=1;
for n=1:repeats
    skeleton(pointer:pointer+(base_con)-1,1)=skeletona;
    if mod(n,2)==0
        skeleton(pointer:pointer+(base_con)-1,2)=pos_every_other_b;
    else
        skeleton(pointer:pointer+(base_con)-1,2)=pos_every_other_a;
    end
    pointer=pointer+base_con;
end

new_index=find(skeleton(:,1)==3)';

new_i_1=find(skeleton(new_index,2)==4)';
new_i_2=find(skeleton(new_index,2)==3)';

mm_index=find(skeleton(:,1)==1)';
match_index=find(skeleton(:,1)==2)';

novels_count=length(new_index)+length(mm_index);

stim_ref_a=randperm(num_trials)+(num_trials*3)+novels_count;%first items - no exemplars
stim_ref=randperm(num_trials*3);%other items - all have 4 exemplars

stim_novel_ref=randperm(novels_count)+(num_trials*3);

stim_test=1:num_trials*3;%possible items for testing lures 

%% to properly couterbalance for the scanner (almost equal number of
%% conditions per block
num_n_block=floor(length(new_index)/num_blocks);
num_m_block=floor(length(match_index)/num_blocks);
num_mm_block=floor(length(mm_index)/num_blocks);

fix_n=[num_n_block num_n_block num_n_block num_n_block num_n_block];%HARD CODED!!!
fix_m=[num_m_block num_m_block num_m_block num_m_block num_m_block];%HARD CODED!!!
fix_mm=[num_mm_block num_mm_block num_mm_block num_mm_block num_mm_block];%HARD CODED!!!

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

%% STRUCTURE Setup
learn_num=1;

new_stims=stim_novel_ref;
new_stims_ref=[];

used=[];
used_ref=[];

scrambled_1={[2,1,4,0],[2,4,1,0],[3,1,4,0],[3,1,2,0],[4,3,2,0],[4,3,1,0]};
scrambled_11=repmat(scrambled_1,1,ceil(length(new_i_1)/length(scrambled_1)));
scrambled_111=scrambled_11(randperm(length(new_i_1)));
scrambled_2={[2,1,0,3],[2,4,0,3],[2,4,0,1],[3,1,0,2],[4,3,0,1],[4,3,0,2]};
scrambled_22=repmat(scrambled_2,1,ceil(length(new_i_2)/length(scrambled_2)));
scrambled_222=scrambled_22(randperm(length(new_i_2)));

for n=1:num_trials
    
    counterlist.trial_info(n).scan.images=[stim_ref_a(1) stim_ref(1:3)];
    counterlist.trial_info(n).scan.images_ref=[1 randi(4) randi(4) randi(4)];
    counterlist.trial_info(n).scan.is_novel=[false false false false];
    stim_ref_a(1)=[];
    stim_ref(1:3)=[];
    
    used=[used counterlist.trial_info(n).scan.images(2:4)];
    used_ref=[used_ref counterlist.trial_info(n).scan.images_ref(2:4)];
    
    counterlist.trial_info(n).novel_type.number=skeleton(n,2);
    switch skeleton(n,2)
        case 4
            counterlist.trial_info(n).novel_type.name='fourth';
            counterlist.trial_info(n).scan.is_novel(4)=true;
        case 3
            counterlist.trial_info(n).novel_type.name='third';
            counterlist.trial_info(n).scan.is_novel(3)=true;
        case 0
            counterlist.trial_info(n).novel_type.name='old';            
    end
        
    switch skeleton(n,1)
        case 2
            counterlist.trial_info(n).trial_type.name='repeat';
            counterlist.trial_info(n).trial_type.number=2;
            counterlist.trial_info(n).pre.images=counterlist.trial_info(n).scan.images;
            counterlist.trial_info(n).pre.images_ref=counterlist.trial_info(n).scan.images_ref;
            counterlist.learn_trials(learn_num)=n;
            counterlist.trial_info(n).orig_order=[1 2 3 4];
            learn_num=learn_num+1;
   
        case 1
            counterlist.trial_info(n).trial_type.name='mismatch';
            counterlist.trial_info(n).trial_type.number=1;
            switch skeleton(n,2)
                case 4
                    counterlist.trial_info(n).pre.images=[counterlist.trial_info(n).scan.images([1 2 3]) stim_novel_ref(1)];
                    counterlist.trial_info(n).pre.images_ref=[counterlist.trial_info(n).scan.images_ref([1 2 3]) randi(4)];
                    new_stims_ref=[new_stims_ref counterlist.trial_info(n).pre.images_ref(4)];
                    counterlist.trial_info(n).orig_order=[1 2 3 0];
                case 3
                    counterlist.trial_info(n).pre.images=[counterlist.trial_info(n).scan.images([1 2]) stim_novel_ref(1) counterlist.trial_info(n).scan.images(4)];
                    counterlist.trial_info(n).pre.images_ref=[counterlist.trial_info(n).scan.images_ref([1 2]) randi(4) counterlist.trial_info(n).scan.images_ref(4)];
                    new_stims_ref=[new_stims_ref counterlist.trial_info(n).pre.images_ref(3)];
                    counterlist.trial_info(n).orig_order=[1 2 0 4];
            end
            stim_novel_ref(1)=[];
            counterlist.learn_trials(learn_num)=n;
            learn_num=learn_num+1;
                                  
        case 3
            counterlist.trial_info(n).trial_type.name='scramble';
            counterlist.trial_info(n).trial_type.number=3;
            switch skeleton(n,2)
                case 4
                    scrambled=scrambled_111{1};
                    scrambled_111(1)=[];
                    counterlist.trial_info(n).pre.images=[counterlist.trial_info(n).scan.images(scrambled(1:3)) stim_novel_ref(1)];
                    counterlist.trial_info(n).pre.images_ref=[counterlist.trial_info(n).scan.images_ref(scrambled(1:3)) randi(4)];
                    new_stims_ref=[new_stims_ref counterlist.trial_info(n).pre.images_ref(4)];
                case 3
                    scrambled=scrambled_222{1};
                    scrambled_222(1)=[];
                    counterlist.trial_info(n).pre.images=[counterlist.trial_info(n).scan.images(scrambled(1:2)) stim_novel_ref(1) counterlist.trial_info(n).scan.images(scrambled(4))];
                    counterlist.trial_info(n).pre.images_ref=[counterlist.trial_info(n).scan.images_ref(scrambled(1:2)) randi(4) counterlist.trial_info(n).scan.images_ref(scrambled(4))];
                    new_stims_ref=[new_stims_ref counterlist.trial_info(n).pre.images_ref(3)];
            end
            counterlist.trial_info(n).orig_order=scrambled;
            stim_novel_ref(1)=[];
            counterlist.learn_trials(learn_num)=n;            
            learn_num=learn_num+1;
    end
    
end

image_test=[];
image_test_ref=[];

for n=1:num_trials
    not_use_test=[called_list counterlist.trial_info(n).scan.images(2:4)];
    
    can_use=setdiff(stim_test,not_use_test);
    
    choice_1=can_use(randi(length(can_use),1));
    choice_1_ref=used_ref(used==choice_1);
    called_list=[called_list choice_1];
    %choice_2=can_use(randi(length(can_use),1));
    %called_list=[called_list choice_2];
    
    counterlist.trial_info(n).test.images=[counterlist.trial_info(n).scan.images choice_1];
    counterlist.trial_info(n).test.images_ref=[counterlist.trial_info(n).scan.images_ref choice_1_ref];
    %counterlist.trial_info(n).test.images=[counterlist.trial_info(n).scan.
    %images choice_1 choice_2];
    
    for i=1:3
        counterlist.image_test(((n-1)*3)+i).images=counterlist.trial_info(n).scan.images(i+1);
        counterlist.image_test(((n-1)*3)+i).images_ref=counterlist.trial_info(n).scan.images_ref(i+1);
        counterlist.image_test(((n-1)*3)+i).seq_image_ref=i+1;
        counterlist.image_test(((n-1)*3)+i).seq_ref=n;
        counterlist.image_test(((n-1)*3)+i).trial_type.name=counterlist.trial_info(n).trial_type.name;
        counterlist.image_test(((n-1)*3)+i).trial_type.number=counterlist.trial_info(n).trial_type.number;
        counterlist.image_test(((n-1)*3)+i).novel=counterlist.trial_info(n).scan.is_novel(i+1);
        counterlist.image_test(((n-1)*3)+i).seq_image_ref_original=counterlist.trial_info(n).orig_order(i+1);
    end
end
counterlist.test_order_item=randperm(length(counterlist.image_test));
%% Pre-exposure/ novelity task
pre_ex_latin=[1 2 3 2 1 2 1 3 2 1 3 1 2 1 2 3 2 1 3 1 2 1 2 3 1 2 3 2];
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
            [~,ref_ref]=ismember(new_order,new_stims);
            counterlist.pre_info.block(n).images_ref=new_stims_ref(ref_ref);
        case 2
            counterlist.pre_info.block(n).repeat_type.name='repeat';
            repeat_order=randperm(pre_per_block);
            repeat_order_a=repeat_order(1:repeat);repeat_order_b=repeat_order(repeat+1:pre_per_block);
            repeat_order=[repeat_order_a repeat_order(repeat) repeat_order_b];
            counterlist.pre_info.block(n).images=repeat_order;
            counterlist.pre_info.block(n).images_ref=ones(1,pre_per_block+1);
        case 3
            counterlist.pre_info.block(n).repeat_type.name='blank';
            counterlist.pre_info.block(n).images=ones(1,pre_per_block+1);
            counterlist.pre_info.block(n).images_ref=ones(1,pre_per_block+1);
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
    %counterlist.trial_info(n).scan.image_names{1}=stims_list_a(counterlist.trial_info(n).scan.images(1));
    for m=1:4
        counterlist.trial_info(n).scan.image_names(m)=stims_list(counterlist.trial_info(n).scan.images(m),counterlist.trial_info(n).scan.images_ref(m));
    end
    counterlist.trial_info(n).test.image_names(1)=stims_list(counterlist.trial_info(n).test.images(1),counterlist.trial_info(n).test.images_ref(1));%outside of loop cause does not need to populate other parts
    for m=2:5
        counterlist.trial_info(n).test.image_names{m}(1)=stims_list(counterlist.trial_info(n).test.images(m),counterlist.trial_info(n).test.images_ref(m));
        other_exemp=1:4;other_exemp=other_exemp(other_exemp~=counterlist.trial_info(n).test.images_ref(m));
        for d=1:length(other_exemp)
            counterlist.trial_info(n).test.image_names{m}(d+1)=stims_list(counterlist.trial_info(n).test.images(m),other_exemp(d));
        end
    end
    
    if ismember(n,counterlist.learn_trials)
        %counterlist.trial_info(n).pre.image_names{1}=stims_list_a(counterlist.trial_info(n).pre.images(1));
        for m=1:4
            counterlist.trial_info(n).pre.image_names(m)=stims_list(counterlist.trial_info(n).pre.images(m),counterlist.trial_info(n).pre.images_ref(m));
        end       
    end
end

for n=1:length(counterlist.image_test)
    counterlist.image_test(n).image_names(1)=stims_list(counterlist.image_test(n).images,counterlist.image_test(n).images_ref);
    other_exemp=1:4;other_exemp=other_exemp(other_exemp~=counterlist.image_test(n).images_ref);
    for d=1:length(other_exemp)
        counterlist.image_test(n).image_names(d+1)=stims_list(counterlist.image_test(n).images,other_exemp(d));
    end
end

for n=1:length(pre_ex_latin)
    for m=1:pre_per_block
        trial_ref=((n-1)*pre_per_block)+m;
        counterlist.pre_trials(trial_ref).block=n;
        switch counterlist.pre_info.block(n).repeat_type.name
            case 'novel'
                counterlist.pre_trials(trial_ref).image=stims_list(counterlist.pre_info.block(n).images(m),counterlist.pre_info.block(n).images_ref(m));
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

%% Make practice file
%
% learn=randperm(3);
% pract_l=randperm(12);
% pract_s=randperm(4)+12;
%
% practice=[];
%
% practice.trial_info(1).scan.images=[pract_s(1) pract_l(1:3)];
% pract_s(1)=[];pract_l(1:3)=[];
% practice.trial_info(1).scan.images_ref=[1 randi(4) randi(4) randi(4)];
% practice.trial_info(1).scan.background=1;
% practice.trial_info(1).trial_type.name='repeat';
% practice.trial_info(1).trial_type.number=1;
% practice.trial_info(1).pre.images=practice.trial_info(1).scan.images;
% practice.trial_info(1).pre.images_ref=practice.trial_info(1).scan.images_ref;
% practice.learn_trials(learn(1))=1;
% practice.trial_info(1).bg_type.name='repeat';
% practice.trial_info(1).bg_type.number=1;
% practice.trial_info(1).pre.background=practice.trial_info(1).scan.background;
%
% practice.trial_info(2).scan.images=[pract_s(1) pract_l(1:3)];
% pract_s(1)=[];pract_l(1:3)=[];
% practice.trial_info(2).scan.images_ref=[1 randi(4) randi(4) randi(4)];
% practice.trial_info(2).scan.background=2;
% practice.trial_info(2).trial_type.name='mismatch';
% practice.trial_info(2).trial_type.number=2;
% practice.trial_info(2).pre.images=practice.trial_info(2).scan.images([1 2 4 3]);
% practice.trial_info(2).pre.images_ref=practice.trial_info(2).scan.images_ref([1 2 4 3]);
% practice.learn_trials(learn(2))=2;
% practice.trial_info(2).bg_type.name='repeat';
% practice.trial_info(2).bg_type.number=1;
% practice.trial_info(2).pre.background=practice.trial_info(1).scan.background;
%
%
% practice.trial_info(3).scan.images=[pract_s(1) pract_l(1:3)];
% pract_s(1)=[];pract_l(1:3)=[];
% practice.trial_info(3).scan.images_ref=[1 randi(4) randi(4) randi(4)];
% practice.trial_info(3).scan.background=3;
% practice.trial_info(3).trial_type.name='mismatch';
% practice.trial_info(3).trial_type.number=2;
% practice.trial_info(3).pre.images=practice.trial_info(3).scan.images([1 2 4 3]);
% practice.trial_info(3).pre.images_ref=practice.trial_info(3).scan.images_ref([1 2 4 3]);
% practice.learn_trials(learn(3))=3;
% practice.trial_info(3).bg_type.name='mismatch';
% practice.trial_info(3).bg_type.number=2;
% practice.trial_info(3).pre.background=5;
%
% practice.trial_info(4).scan.images=[pract_s(1) pract_l(1:3)];
% pract_s(1)=[];pract_l(1:3)=[];
% practice.trial_info(4).scan.images_ref=[1 randi(4) randi(4) randi(4)];
% practice.trial_info(4).scan.background=4;
% practice.trial_info(4).trial_type.name='new';
% practice.trial_info(4).trial_type.number=3;
% practice.trial_info(4).bg_type.name='new';
% practice.trial_info(4).bg_type.number=3;
%
%
% practice.trial_info(1).test.images=[practice.trial_info(1).scan.images practice.trial_info(2).scan.images(2)];
% practice.trial_info(1).test.images_ref=[practice.trial_info(1).scan.images_ref practice.trial_info(2).scan.images_ref(2)];
%
% practice.trial_info(2).test.images=[practice.trial_info(2).scan.images practice.trial_info(3).scan.images(3)];
% practice.trial_info(2).test.images_ref=[practice.trial_info(2).scan.images_ref practice.trial_info(3).scan.images_ref(3)];
%
% practice.trial_info(3).test.images=[practice.trial_info(3).scan.images practice.trial_info(4).scan.images(4)];
% practice.trial_info(3).test.images_ref=[practice.trial_info(3).scan.images_ref practice.trial_info(4).scan.images_ref(4)];
%
% practice.trial_info(4).test.images=[practice.trial_info(4).scan.images practice.trial_info(1).scan.images(2)];
% practice.trial_info(4).test.images_ref=[practice.trial_info(4).scan.images_ref practice.trial_info(1).scan.images_ref(2)];
%
%
% repeats_setup=[1 2 3 4 5 5 6 7 8 9 10];
% for n=1:length(repeats_setup)
%    practice.pre_trials(n).number=repeats_setup(n);
% end
%
% for n=1:length(practice.trial_info) 
%     for i=1:3
%         practice.image_test(((n-1)*3)+i).images=practice.trial_info(n).scan.images(i+1);
%         practice.image_test(((n-1)*3)+i).images_ref=practice.trial_info(n).scan.images_ref(i+1);
%         practice.image_test(((n-1)*3)+i).seq_image_ref=i+1;
%         practice.image_test(((n-1)*3)+i).seq_ref=n;
%         practice.image_test(((n-1)*3)+i).trial_type.name=practice.trial_info(n).trial_type.name;
%         practice.image_test(((n-1)*3)+i).trial_type.number=practice.trial_info(n).trial_type.number;
%     end
% end
% practice.test_order_item=randperm(length(practice.image_test));
% 
% pract_list=[];%change for actual name
% bg_list=[];
% repeats_list=[];
% load([base_dir '/stims/repeats_names.mat'])
% load([base_dir '/stims/pract_names.mat'])
% load([base_dir '/stims/bg_names.mat'])
%
% for n=1:4
%     for m=1:4
%         practice.trial_info(n).scan.image_names(m)=pract_list(practice.trial_info(n).scan.images(m),practice.trial_info(n).scan.images_ref(m));
%     end
%     practice.trial_info(n).test.image_names(1)=pract_list(practice.trial_info(n).test.images(1),practice.trial_info(n).test.images_ref(1));%outside of loop cause does not need to populate other parts
%     for m=2:5
%         practice.trial_info(n).test.image_names{m}(1)=pract_list(practice.trial_info(n).test.images(m),practice.trial_info(n).test.images_ref(m));
%         other_exemp=1:4;other_exemp=other_exemp(other_exemp~=practice.trial_info(n).test.images_ref(m));
%         for d=1:length(other_exemp)
%             practice.trial_info(n).test.image_names{m}(d+1)=pract_list(practice.trial_info(n).test.images(m),other_exemp(d));
%         end
%     end
%     practice.trial_info(n).scan.bg_name=bg_list(practice.trial_info(n).scan.background);
%     if ismember(n,practice.learn_trials)
%         for m=1:4
%             practice.trial_info(n).pre.image_names(m)=pract_list(practice.trial_info(n).pre.images(m),practice.trial_info(n).pre.images_ref(m));
%         end
%         practice.trial_info(n).pre.bg_name=bg_list(practice.trial_info(n).pre.background);
%     end
% end
%
% for n=1:length(practice.pre_trials)
%    practice.pre_trials(n).image=repeats_list(practice.pre_trials(n).number);
% end
%
% for n=1:length(practice.image_test)
%     practice.image_test(n).image_names(1)=pract_list(practice.image_test(n).images,practice.image_test(n).images_ref);
%     other_exemp=1:4;other_exemp=other_exemp(other_exemp~=practice.image_test(n).images_ref);
%     for d=1:length(other_exemp)
%         practice.image_test(n).image_names(d+1)=pract_list(practice.image_test(n).images,other_exemp(d));
%     end
% end
% save([base_dir '/stims/practice.mat'],'practice');
%%
end
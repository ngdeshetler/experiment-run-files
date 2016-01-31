function mm_ref = genmm(trials, stim, probe)

%%%%this function creates a randomized counterbalanced reference list for the mismatch probe type.  
%%%%This is needed since for each mismatch an image from a different catagory that the correct pair needs to be presented.  
%%%%This list insures that there are a balanced number of probes from the different catagories, and that eahc one is unique, and can be called from the same image list as the stims%%%%%

%%%created by Natalie De Shetler, Jan 18, 2012%%%

%%%%Doesn't need shuffle of rng since it is called in the script where this
%%%%is used

trials_stim = trials/stim;%trials per stimuli type
trials_probe = trials_stim/probe;%trials per probe type per stimuli catagory
other_cats_lenght=trials_probe/(stim-1);%the number of mismatches needed for each catagory per initial catagory

ref_mm=1:trials_probe;
ref_mm=ref_mm'+ trials_stim;%creates reference for each image that is from the same list as the other stims, these should be the single images that dont have pairs
pre_expose=ones(trials_probe/2,1);%the first half of the mismatches are pre-exposed
no_pre=pre_expose*-1;%the second hald is not pre-exposed
expose=cat(1,pre_expose,no_pre);%makes a reference for the pre-exposure


%creates list of catagorys for probe and references
for n = 1:stim
    type=ones(trials_probe,1)*n;
    mm_type_r=cat(2,type,ref_mm,expose);%each row has the cat type, the cat reference, and if it is pre-exposed
    mm_type{n}=mm_type_r;
    type_after{n}=ones(other_cats_lenght,1)*n;
end

%creates the each catagory of stim that will call eacg catagorys for probe, all excluding that catagory
for n = 1:stim
    ordered_other{n}=cat(1,type_after{1:end ~= n});
end

%mixes the type of catagory of the original
for n = 1:stim
    j=length(ordered_other{n});
    which_ordered=ordered_other{n};
    index=randperm(j);
    index_ref{n}=index;
    for i=1:j
        k=index(i);
        rand_cat(i)=which_ordered(k);
    end
    random_other{n}=rand_cat';
end

%combines list for that for each probe catagory there is a reference number and a counterbalanced number of original stim catagories
mm_type_c=cat(1,mm_type{:});
random_other_c=cat(1,random_other{:});
ordered_mm=cat(2,mm_type_c,random_other_c);

%randomizes whole list
mix_index=randperm(trials_stim);
for i=1:trials_stim
    k=mix_index(i);
    mixed_mm(i,:)=ordered_mm(k,:);
end

a=1;
b=1;
c=1;

%creates the matrixes that will be called depending on the catagory of the stim
%%%%%%NOTE: This is hard coded for 3 catagory types, would need to be changed if stim # changes%%%%%%%%
for n=1:trials_stim
    if mixed_mm(n,4)==1
        first_cat(a,:)=mixed_mm(n,:);
        a=a+1;
    elseif mixed_mm(n,4)==2
        sec_cat(b,:)=mixed_mm(n,:);
        b=b+1;
    else
        third_cat(c,:)=mixed_mm(n,:);
        c=c+1;
    end
end

%%%again, hard coded for 3 catagories%%%%%
mm_ref{1}=first_cat;
mm_ref{2}=sec_cat;
mm_ref{3}=third_cat;

%%%%   OUTPUT ORDER  %%%%%
%  Probe Catagory;   Probe Reference;   Pre-exposed;  Original Stim Catagory  %

end


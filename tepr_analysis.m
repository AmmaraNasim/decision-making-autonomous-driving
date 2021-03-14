
clc
clear all

addpath('E:\Ammara_UOL\Practical_project\my_practical_project');
load('intersection_timestamp.mat'); 

%% Loading data for subjects

for subject = 1:1:7
    for trial = 1:1:3
        for video = 1:1:2
%     eyetracking data
    eyedata{trial,subject}{video}=load(['E:\Ammara_UOL\Practical_project\my_practical_project\Imported data\Eyetracking\v',num2str(subject), num2str(trial),num2str(video),'fixation.mat',]);
 
    %Presentation log files
    logdata{trial,subject}{video}=load(['E:\Ammara_UOL\Practical_project\my_practical_project\Imported data\Presentation data\v' ,num2str(subject), num2str(trial),num2str(video),'event.mat']);
        end 
    end 
end 

%% Data preprocessing - interpolation

for subject = 1:1:7
    for trial = 1:1:3
        for video = 1:1:2
        
        %creating names for indexing
        %eyetracking
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];


        %create corrected time stamp (starting with 1 in ms)
        eyedata{trial, subject}{video}.(filenameE).TIMESTAMPc = eyedata{trial, subject}{video}.(filenameE).TIMESTAMP - (eyedata{trial, subject}{video}.(filenameE).TIMESTAMP(1)-1);
        
        
        %Step 1. Preprocessing: Identifiing Eye-blink artifacts and replacing by linear interpolation
        %finding data for interpolation - x values where eyeblink starts and
        %finishes and corresponding y values
        
        c = 1;
        b = 1;
        RPS = [];  %cant preallocate...size varies
        x = [];
        
        %set last datapoint to not in eyeblink
        eyedata{trial, subject}{video}.(filenameE).RIGHT_IN_BLINK(size(eyedata{trial, subject}{video}.(filenameE),1)-1) = 0;
        
        for ii = 2:1:size(eyedata{trial, subject}{video}.(filenameE).RIGHT_IN_BLINK,1)-1 %loop through eyedata
            if eyedata{trial, subject}{video}.(filenameE).RIGHT_IN_BLINK(ii-1) == 0 && eyedata{trial, subject}{video}.(filenameE).RIGHT_IN_BLINK(ii) == 1 %find instances blink starts
                RPS(b,1) = eyedata{trial, subject}{video}.(filenameE).RIGHT_PUPIL_SIZE(ii);    %save y value of blink start
                x(b,1) = eyedata{trial, subject}{video}.(filenameE).TIMESTAMPc(ii); %save x value of blink start
                RVY(b,1) = eyedata{trial, subject}{video}.(filenameE).RIGHT_GAZE_Y(ii);
                RVX(b,1) = eyedata{trial, subject}{video}.(filenameE).RIGHT_GAZE_X(ii);
                b = b + 1;
            end
            if eyedata{trial, subject}{video}.(filenameE).RIGHT_IN_BLINK(ii) == 1 && eyedata{trial, subject}{video}.(filenameE).RIGHT_IN_BLINK(ii+1) == 0 && ~isempty(x) %find instances blink ends
                RPS(c,2) = eyedata{trial, subject}{video}.(filenameE).RIGHT_PUPIL_SIZE(ii);
                x(c,2) = eyedata{trial, subject}{video}.(filenameE).TIMESTAMPc(ii);
                RVY(c,2) = eyedata{trial, subject}{video}.(filenameE).RIGHT_GAZE_Y(ii);
                RVX(c,2) = eyedata{trial, subject}{video}.(filenameE).RIGHT_GAZE_X(ii);
                c = c + 1;
            end
            
        end
        if c ~= b, disp('There is an issue finding intorpolation time points..'); end
        % NaN can be saved in case the data ends on an eyeblink...remove
        % data in v that contains NaN:
        if isnan(RPS(end,2))     
            RPS(end,:) = [];
            x(end,:) = [];
            RVY(end,:) = [];
            RVX(end,:) = [];
        end
        
        %another problem can be a zero at the end...
        
        if  RPS(end,2) == 0     
            RPS(end,:) = [];
            x(end,:) = [];
            RVY(end,:) = [];
            RVX(end,:) = [];
        end
        
        %length of interpolated coordinates
        lenint = abs(x(:,1) - x(:,2)); 
        
%         visualizing before interpolation
%         
%         for ii = 1:2 %throws out 138 plots or more - dont execute lightly
%         
%         xx = linspace(x(ii,1),x(ii,2),lenint(ii,1)+100);
%         figure
%         scatter(xx,eyedata{trial, subject}.(filenameE).RIGHT_PUPIL_SIZE(x(ii,1)-49:x(ii,2)+50))
%         ylim([0 2000])
%         
%         end
        
        
        %interpolation
        
        for ii = 1:1:size(x,1) %loop through coordinates
            
            xq = linspace(x(ii,1),x(ii,2),lenint(ii,1)); %create line vector -- equal to ms in the data gap to be filled in
            
            eyedata{trial, subject}{video}.(filenameE).RIGHT_PUPIL_SIZE(x(ii,1):x(ii,2)-1) = (interp1(x(ii,1:2),RPS(ii,1:2),xq))'; %use interp1 to create a linear interpolation - feed it x start stop, y (here v) value at start and stop, plus the line vector to be used
            eyedata{trial, subject}{video}.(filenameE).RIGHT_GAZE_Y(x(ii,1):x(ii,2)-1) = (interp1(x(ii,1:2),RVY(ii,1:2),xq))';
            eyedata{trial, subject}{video}.(filenameE).RIGHT_GAZE_X(x(ii,1):x(ii,2)-1) = (interp1(x(ii,1:2),RVX(ii,1:2),xq))';
        end
        
        %visualizing interpolated elements
        
%       for ii = 250:1:252 %throws out 138 plots - dont execute lightly
%          
%       xx = linspace(x(ii,1),x(ii,2),lenint(ii,1)+100);
%       figure
%       scatter(xx,eyedata{trial, subject}.(filenameE).RIGHT_PUPIL_SIZE(x(ii,1)-49:x(ii,2)+50))
%       ylim([0 2500])
%       end

    %detrending psize data for testing
        end 
        disp(['Interpolation subject: ',num2str(subject),' trial: ',num2str(trial),' completed..'])
    end
end


%% Aligning timestamp

%original eyetracking data (using edf2asc converter) has the information about MRI trigger corresponding
%to the pulse in presentation data in event table

% 1. MSG	3177192 Start Video corresponds to end of the first video
% 2. MSG	3605023 Start Video corresponds to end of second video in video
% stimuli 



for subject = 1:1:7
    for trial = 1:1:3
        for video = 1:1:2
        
        %creating names for indexing
        %eyetracking
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        %presentation log
        filenameP = ['v',num2str(subject),num2str(trial),num2str(video),'event'];
        
%         
        eyedata{trial, subject}{video}.(filenameE).timecor=  eyedata{trial, subject}{video}.(filenameE).TIMESTAMP-(eyedata{trial, subject}{video}.(filenameE).TIMESTAMP(1)-1);      

% time aligning for presentation data 
% presentation data in 10th of ms, divide by 10
% converting stimulus time into ms from 10th of ms

       logdata{trial, subject}{video}.(filenameP).timecor=logdata{trial, subject}{video}.(filenameP).ReqTime/10;



        end 
    end 
end 

disp('Data alignment completed..')

%% %% Normalization Pupilsize


for subject = 1:1:7
     for trial = 1:1:3 
         for video = 1:1:2
         b = 1;
        %creating names for indexing
        %eyetracking
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        %presentation log
        filenameP = ['v',num2str(subject),num2str(trial),num2str(video),'event'];
        
        nortimes{trial,subject}{video}(b,1) = 1;
        nortimes{trial,subject}{video}(b,2) = logdata{trial, subject}{video}.(filenameP).timecor(end)+5000;  % last stimulus also lasts for 5 secs so video end after that
        nortimesdiff{trial,subject}{video} = int64(nortimes{trial,subject}{video}(b,2)) - int64(nortimes{trial,subject}{video}(b,1));
        b = b + 1;
         end 
     end 
end 
%reading out data per subject and averageing it

trial = 1;
video = 1;

for subject = 1:1:7
    trial = 1;
    video = 1;

    for count = 1:1:6
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        nordata(count,1:nortimesdiff{trial,subject}{video}+1,subject) = eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZE(int64(nortimes{trial,subject}{video}(1)):int64(nortimes{trial,subject}{video}(2)))';
        video = video+1; 
        if mod(count,2) == 0, trial = trial + 1; video = 1; end
    end
end

nordata(nordata == 0) = NaN; %converting buffer zeros to NaN

%finding means of subject
for subject = 1:1:7
    normean(subject) = nanmean(nanmean(nordata(:,:,subject),2),1); 
end

%finding std
for subject = 1:1:7
  norstd(subject) = nanstd(nanstd(nordata(:,:,subject),0,2),0,1);
end

%normalization
for subject = 1:1:7
    for trial = 1:1:3  
        for video = 1:1:2
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn = (eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZE - normean(1,subject))./norstd(1,subject);
        end 
    end
end

disp('Normalization completed..')


%% Epoching around decision making (interscection point)

        dec_epoch_nb2 =cell(3,7);
        dec_epoch_nb0 = cell(3,7);
        
        lenepoch = ([3000 3000]);
        len_epo = 6000;       
        
for subject = 1:1:7
    
    for trial = 1:1:3
        
        for video = 1:1:2
        %creating names for indexing
        %eyetracking    
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        %video
        filenameV = ['video',num2str(video)];
        
         if  mod(trial,2)~=0  && video == 1  || mod(trial,2)==0 && video == 2
            for ii = 1:1:size(Intersectiontimestamps.video1,1)
                dec_epoch_nb2{trial,subject} = [dec_epoch_nb2{trial,subject}; eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn(Intersectiontimestamps.(filenameV)(ii,trial)-lenepoch(1):Intersectiontimestamps.(filenameV)(ii,trial)+lenepoch(2)-1)'];
            end
         end
         if  mod(trial,2)==0  && video == 1 || mod(trial,2)~=0 && video == 2
            for ii = 1:1:size(Intersectiontimestamps.video1,1)
                dec_epoch_nb0{trial,subject} = [dec_epoch_nb0{trial,subject}; eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn(Intersectiontimestamps.(filenameV)(ii,trial)-lenepoch(1):Intersectiontimestamps.(filenameV)(ii,trial)+lenepoch(2)-1)'];
            end
         end
        end 
    end 
end 
disp('Epoching around decision making done');


%% Visualization of decision making 



epoch_nb0_aut = [];
epoch_nb2_aut = [];

for subject = 1:1:7
    
    for trial = 1:1:3
        
       
        
        epoch_nb0_aut = [epoch_nb0_aut; dec_epoch_nb0{trial,subject}];
        epoch_nb2_aut = [epoch_nb2_aut; dec_epoch_nb2{trial,subject}];
        
         if trial == 3
             
    
        
            options1.handle     = subject;
            options1.color_area = [128 193 219]./255;    % Blue theme
            options1.color_line = [ 52 148 186]./255;
            options1.alpha      = 0.5;
            options1.line_width = 2;
            options1.error = 'c95';
            
            options2.handle     = subject;
            options2.color_area = [243 169 114]./255;    % Orange theme
            options2.color_line = [236 112  22]./255;
            options2.alpha      = 0.5;
            options2.line_width = 2;
            options2.error = 'c95';

            
            figure
            plot_areaerrorbar(epoch_nb0_aut,options1)
            hold on
            plot_areaerrorbar(epoch_nb2_aut,options2)
            xline(3000,'-',{'Decision','Point'},'fontweight','bold');
            hold on
            set(gca,'fontweight','bold');
            grid
            xlabel('Time [ms]','fontweight','bold','fontsize',14)
            ylabel('Mean pupil size (z-score normalized)','fontweight','bold','fontsize',14)
            if subject == 2
            ylim([-6 18])
            yticks([-6 -3 0 3 6 9 12 15 18])
            end 
            if subject == 3
            ylim([-5 20])
            end 
            
            title(['TEPR by n-back task for subject ',num2str(subject)],'fontweight','bold','fontsize',14)
            legend('nb0','nb2','Location','northwest')
            hold off
            


      
         end 
    
     end   
             mean_nb0{subject} = mean(epoch_nb0_aut,1);
             mean_nb2{subject} = mean(epoch_nb2_aut,1);
             epoch_nb0_aut = [];
             epoch_nb2_aut = [];
end


%% Epoching around button press
 
targetbuttonnb2 = cell(3,7);
nontarget_buttonnb2 = cell(3,7);
targetbuttonnb0 = cell(3,7);
nontarget_buttonnb0 = cell(3,7);


interv = 3000;
 
for subject = 1:1:7
    
    for trial = 1:1:3
        
        for video = 1:1:2
        %creating names for indexing
        %eyetracking
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        %presentation log
        filenameP = ['v',num2str(subject),num2str(trial),num2str(video),'event'];
        %Target buttons 
    if mod(trial,2)~=0  && video == 1  || mod(trial,2)==0 && video == 2 %nback2 
              
           % for nback 2
          
           b = 1;
        for ii = 1:1:size(logdata{trial, subject}{video}.(filenameP).Code,1)
            if logdata{trial, subject}{video}.(filenameP).Code(ii) == 'hit'  
                targetbuttonnb2{trial,subject}(b,1) = logdata{trial, subject}{video}.(filenameP).timecor(ii);
                b = b + 1;
            end            
        end
         % non target buttons
    
        %for nback 2
        
        b = 1;
    
        for ii = 1:1:size(logdata{trial, subject}{video}.(filenameP).Code,1)
            if logdata{trial, subject}{video}.(filenameP).Code(ii) == 'FALSE'  
                nontarget_buttonnb2{trial,subject}(b,1) = logdata{trial, subject}{video}.(filenameP).timecor(ii);
                b = b + 1;
            end
        end
    end 
    
  if  mod(trial,2)==0  && video == 1 || mod(trial,2)~=0 && video == 2
        % for nback 0
        
           b = 1;
        for ii = 1:1:size(logdata{trial, subject}{video}.(filenameP),1)
            if logdata{trial, subject}{video}.(filenameP).Code(ii) == 'hit'  
                targetbuttonnb0{trial,subject}(b,1) = logdata{trial, subject}{video}.(filenameP).timecor(ii);
                b = b + 1;
            end            
        end
        %non-target buttons
        % for nback 0
         
        b = 1;
    
        for ii = 1:1:size(logdata{trial, subject}{video}.(filenameP).Code,1)
            if logdata{trial, subject}{video}.(filenameP).Code(ii) == 'FALSE'  
                nontarget_buttonnb0{trial,subject}(b,1) = logdata{trial, subject}{video}.(filenameP).timecor(ii);
                b = b + 1;
            end
        end
    
  end 
        end 
    end 
end



%% Epoching 

        targetb_epoch_nb2 =cell(3,7);
        targetb_epoch_nb0 = cell(3,7);
        non_targetb_epoch_nb2 = cell(3,7);
        non_targetb_epoch_nb0 = cell(3,7);
        
        
for subject = 1:1:7
    for trial = 1:1:3
        for video = 1:1:2
        filenameE = ['v',num2str(subject),num2str(trial),num2str(video),'fixation'];
        
         if  mod(trial,2)~=0  && video == 1  || mod(trial,2)==0 && video == 2  %nback2
            for ii = 1:1:size(targetbuttonnb2{trial,subject},1)
                targetb_epoch_nb2{trial,subject} = [targetb_epoch_nb2{trial,subject}; eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn(targetbuttonnb2{trial,subject}(ii,1)-500:targetbuttonnb2{trial,subject}(ii,1)+interv-501)'];
            end
            
            for ii = 1:1:size(nontarget_buttonnb2{trial,subject},1)
                non_targetb_epoch_nb2{trial,subject} = [non_targetb_epoch_nb2{trial,subject}; eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn(nontarget_buttonnb2{trial,subject}(ii,1)-500:nontarget_buttonnb2{trial,subject}(ii,1)+interv-501)'];
            end
         end
          if  mod(trial,2)==0  && video == 1 || mod(trial,2)~=0 && video == 2  %nback0
            for ii = 1:1:size(targetbuttonnb0{trial,subject},1)
                targetb_epoch_nb0{trial,subject} = [targetb_epoch_nb0{trial,subject}; eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn(targetbuttonnb0{trial,subject}(ii,1)-500:targetbuttonnb0{trial,subject}(ii,1)+interv-501)'];
            end
            
            for ii = 1:1:size(nontarget_buttonnb0{trial,subject},1)
                non_targetb_epoch_nb0{trial,subject} = [non_targetb_epoch_nb0{trial,subject}; eyedata{trial,subject}{video}.(filenameE).RIGHT_PUPIL_SIZEn(nontarget_buttonnb0{trial,subject}(ii,1)-500:nontarget_buttonnb0{trial,subject}(ii,1)+interv-501)'];
            end
          
          end
        end 
    end 
end 
 

%%  Visualization 


epoch_nb0_all_target = [];
epoch_nb0_all_notarget = [];
epoch_nb2_all_target = [];
epoch_nb2_all_notarget = [];


x = linspace(1,2,interv);

for subject = 1:1:7
    
     for trial = 1:1:3    
         
       
        
        

        epoch_nb0_all_target = [epoch_nb0_all_target; targetb_epoch_nb0{trial,subject}];
        epoch_nb0_all_notarget = [epoch_nb0_all_notarget; non_targetb_epoch_nb0{trial,subject}]; 
       
        epoch_nb2_all_target = [epoch_nb2_all_target; targetb_epoch_nb2{trial,subject}];
        epoch_nb2_all_notarget = [epoch_nb2_all_notarget; non_targetb_epoch_nb2{trial,subject}];
              
               
               
          if trial == 3
             


       
            
            options1.handle     = subject;
            options1.color_area = [128 193 219]./255;    % Blue theme
            options1.color_line = [ 52 148 186]./255;
            options1.alpha      = 0.5;
            options1.line_width = 2;
            options1.error = 'c95';
            
            options2.handle     = subject;
            options2.color_area = [243 169 114]./255;    % Orange theme
            options2.color_line = [236 112  22]./255;
            options2.alpha      = 0.5;
            options2.line_width = 2;
            options2.error = 'c95';
            
            options3.handle     = subject;
            options3.color_area = [243 209 131]./255;    % yellow theme
            options3.color_line = [236 176  31]./255;
            options3.alpha      = 0.5;
            options3.line_width = 2;
            options3.error = 'c95';
            
            options4.handle     = subject;
            options4.color_area = [143 169 134]./255;    % green theme
            options4.color_line = [118 171  47]./255;
            options4.alpha      = 0.5;
            options4.line_width = 2;
            options4.error = 'c95';
            
            
            figure
            plot_areaerrorbar(epoch_nb0_all_target,options1)
            hold on
            plot_areaerrorbar(epoch_nb0_all_notarget,options2)
            hold on
            plot_areaerrorbar(epoch_nb2_all_target,options3)
            hold on
            plot_areaerrorbar(epoch_nb2_all_notarget,options4)
            hold on
            grid
           
            xlabel('Time [ms]','fontweight','bold','fontsize',14)
            ylabel('Mean pupil size (z-score normalized)','fontweight','bold','fontsize',14)
            if subject == 2
            ylim([-4 12])
            end 
            if subject == 3
            ylim([-5 15])
            end  
            set(gca,'fontweight','bold');
            title(['TEPRs of 0-back/2-back for target vs notarget for subject ',num2str(subject)],'fontweight','bold','fontsize',14)
            legend('target nb0','non target nb0','target nb2','non target nb2','Location','northwest')
            hold off
            
 
 
            

             
          end 
     end
             mean_nb0_target{subject} = mean(epoch_nb0_all_target,1);
             mean_nb2_target{subject} = mean(epoch_nb2_all_target,1);
             mean_nb0_notarget{subject} = mean(epoch_nb0_all_notarget,1);
             mean_nb2_notarget{subject} = mean(epoch_nb2_all_notarget,1);
             
     epoch_nb0_all_target = [];
     epoch_nb0_all_notarget = [];
    
     epoch_nb2_all_target = [];
     epoch_nb2_all_notarget = [];
end  

%% Mistakes found 

b = 1;
c = 1;
for subject = 1:1:7
    for trial = 1:1:3
        for video = 1:2
             %presentation log
        filenameP = ['v',num2str(subject),num2str(trial),num2str(video),'event'];
        
             for ii = 1:1:size(logdata{trial, subject}{video}.(filenameP).Code,1)
                     if  mod(trial,2)~=0  && video == 1  || mod(trial,2)==0 && video == 2
                          if logdata{trial, subject}{video}.(filenameP).Code(ii) == 'hit'  && logdata{trial, subject}{video}.(filenameP).Type(ii) == 'miss'
                                        b= b+ 1;
                          end 
                     end 
                     if mod(trial,2)==0  && video == 1 || mod(trial,2)~=0 && video == 2
                            if logdata{trial, subject}{video}.(filenameP).Code(ii) == 'hit'  && logdata{trial, subject}{video}.(filenameP).Type(ii) == 'miss'
                                c = c+ 1;
                            end 
            
                    end
             end 
        end
   end 
    
             mistakes_nb2(subject) = b;
             mistakes_nb0(subject) = c;
             
             b = 1;
             c = 1;            
end 

y = [mistakes_nb0;mistakes_nb2]';
figure
h = bar(y);    
title('Performance in Working Memory Task','fontweight','bold','fontsize',14)
xlabel('Number of Subjects','fontweight','bold','fontsize',14);
ylabel('Number of Mistakes','fontweight','bold','fontsize',14);
set(h,{'DisplayName'}, {'nback0','nback2'}')
set(gca,'fontweight','bold');
legend()




%% ANOVA for nb0 vs nb2-dec autonomous and manual driving conditions

% extracting maximum values and timepoints for anova


win_len = 500; % 0.5 secs
max_nb0_aut = zeros(1,5);
max_nb0_manual = zeros(1,5);
max_nb2_aut = zeros(1,5);
max_nb2_manual = zeros(1,5);

max_index_nb0_aut = zeros(1,5);
max_index_nb0_manual = zeros(1,5);
max_index_nb2_aut = zeros(1,5);
max_index_nb2_manual = zeros(1,5);


for subject = 1:1:7
    
    
%     finding max
    max_nb0_aut(subject) = max(mean_nb0{subject});
    max_nb0_manual(subject) = max(mean_nb0_manual{subject});
    max_nb2_aut(subject) = max(mean_nb2{subject}); 
    if subject ==2
    max_nb2_manual(subject) = max(mean_nb2_manual{subject}(3000:end));
    else 
    max_nb2_manual(subject) = max(mean_nb2_manual{subject});
    end 
    
%     indexing
    max_index_nb0_aut(subject) = find(mean_nb0{subject}==max_nb0_aut(subject), 1, 'last' );
    max_index_nb0_manual(subject) = find(mean_nb0_manual{subject}==max_nb0_manual(subject), 1, 'last' );
    max_index_nb2_aut(subject) = find(mean_nb2{subject}==max_nb2_aut(subject), 1, 'last' );
    max_index_nb2_manual(subject) = find(mean_nb2_manual{subject}==max_nb2_manual(subject), 1, 'last' );
 
    
  for count = 1:3
      index_nb0_aut{subject}(count) = max_index_nb0_aut(subject)-win_len*(count);
      index_nb0_manual{subject}(count) = max_index_nb0_manual(subject)-win_len*(count);
      index_nb2_aut{subject}(count) = max_index_nb2_aut(subject)-win_len*(count);
      index_nb2_manual{subject}(count) = max_index_nb2_manual(subject)-win_len*(count);
  end 
  index_nb0_aut{subject}(4) = max_index_nb0_aut(subject);
  index_nb0_manual{subject}(4) = max_index_nb0_manual(subject);
  index_nb2_aut{subject}(4) = max_index_nb2_aut(subject);
  index_nb2_manual{subject}(4) = max_index_nb2_manual(subject);
  
  index_nb0_aut{subject}(count+2) = max_index_nb0_aut(subject)+win_len;
  index_nb0_aut{subject} = sort(index_nb0_aut{subject});
  index_nb0_manual{subject}(count+2) = max_index_nb0_manual(subject)+win_len;
  index_nb0_manual{subject} = sort(index_nb0_manual{subject});
  index_nb2_aut{subject}(count+2) = max_index_nb2_aut(subject)+win_len;
  index_nb2_aut{subject} = sort(index_nb2_aut{subject});
  index_nb2_manual{subject}(count+2) = max_index_nb2_manual(subject)+win_len;
  index_nb2_manual{subject} = sort(index_nb2_manual{subject});
  
  % obtaining values for ANOVA
  anova_nb0_aut{subject} = mean_nb0{subject}(index_nb0_aut{subject});
  anova_nb0_manual{subject} = mean_nb0_manual{subject}(index_nb0_manual{subject});
  anova_nb2_aut{subject} = mean_nb2{subject}(index_nb2_aut{subject});
  anova_nb2_manual{subject} = mean_nb2_manual{subject}( index_nb2_manual{subject});
end 

%% ANOVA for nb0 vs nb2-dec autonomous and manual driving conditions
 
y=[];
a = [];
b = [];

for subject = 1:1:7
    
         
           a{subject} = [anova_nb0_manual{subject}';anova_nb2_manual{subject}'];
           b{subject} = [anova_nb0_aut{subject}';anova_nb2_aut{subject}'];
           y{subject} = horzcat(a{subject},b{subject});
           reps = size(anova_nb0_manual{subject},2);
           [p,tbl,stats] = anova2(y{subject},reps);

        
end 

%% ANOVA for target vs non-target autonomous and manual driving conditions

% extracting maximum values and timepoints for anova


win_len = 300; % 0.5 secs
max_tnb0_aut = zeros(1,7);
max_tnb0_manual = zeros(1,7);
max_tnb2_aut = zeros(1,7);
max_tnb2_manual = zeros(1,7);

max_index_tnb0_aut = zeros(1,7);
max_index_tnb0_manual = zeros(1,7);
max_index_tnb2_aut = zeros(1,7);
max_index_tnb2_manual = zeros(1,7);


for subject = 1:1:7
    
%     finding max
    max_tnb0_aut(subject) = max(mean_nb0_target{subject});
    max_tnb0_manual(subject) = max(mean_nb0_target_manual{subject});
    max_tnb2_aut(subject) = max(mean_nb2_target{subject}); 
    max_tnb2_manual(subject) = max(mean_nb2_target_manual{subject});
    
%     indexing
    max_index_tnb0_aut(subject) = find(mean_nb0_target{subject}==max_tnb0_aut(subject));
    max_index_tnb0_manual(subject) = find(mean_nb0_target_manual{subject}==max_tnb0_manual(subject));
    max_index_tnb2_aut(subject) = find(mean_nb2_target{subject}==max_tnb2_aut(subject));
    max_index_tnb2_manual(subject) = find(mean_nb2_target_manual{subject}==max_tnb2_manual(subject), 1, 'last' );

    
  for count = 1:3
      index_tnb0_aut{subject}(count) = max_index_tnb0_aut(subject)-win_len*(count);
      index_tnb0_manual{subject}(count) = max_index_tnb0_manual(subject)-win_len*(count);
      index_tnb2_aut{subject}(count) = max_index_tnb2_aut(subject)-win_len*(count);
      index_tnb2_manual{subject}(count) = max_index_tnb2_manual(subject)-win_len*(count);
  end 
  index_tnb0_aut{subject}(4) = max_index_tnb0_aut(subject);
  index_tnb0_manual{subject}(4) = max_index_tnb0_manual(subject);
  index_tnb2_aut{subject}(4) = max_index_tnb2_aut(subject);
  index_tnb2_manual{subject}(4) = max_index_tnb2_manual(subject);
  
  index_tnb0_aut{subject}(count+2) = max_index_tnb0_aut(subject)+win_len;
  index_tnb0_aut{subject} = sort(index_tnb0_aut{subject});
  index_tnb0_manual{subject}(count+2) = max_index_tnb0_manual(subject)+win_len;
  index_tnb0_manual{subject} = sort(index_tnb0_manual{subject});
  index_tnb2_aut{subject}(count+2) = max_index_tnb2_aut(subject)+win_len;
  index_tnb2_aut{subject} = sort(index_tnb2_aut{subject});
  index_tnb2_manual{subject}(count+2) = max_index_tnb2_manual(subject)+win_len;
  index_tnb2_manual{subject} = sort(index_tnb2_manual{subject});
  
  % obtaining values for ANOVA
  anova_tnb0_aut{subject} = mean_nb0_target{subject}(index_tnb0_aut{subject});
  anova_tnb0_manual{subject} = mean_nb0_target_manual{subject}(index_tnb0_manual{subject});
  anova_tnb2_aut{subject} = mean_nb2_target{subject}(index_tnb2_aut{subject});
  anova_tnb2_manual{subject} = mean_nb2_target_manual{subject}( index_tnb2_manual{subject});
end

% no target

win_len = 300; % 0.3 secs
max_not_nb0_aut = zeros(1,5);
max_not_nb0_manual = zeros(1,5);
max_not_nb2_aut = zeros(1,5);
max_not_nb2_manual = zeros(1,5);

max_index_not_nb0_aut = zeros(1,5);
max_index_not_nb0_manual = zeros(1,5);
max_index_not_nb2_aut = zeros(1,5);
max_index_not_nb2_manual = zeros(1,5);


for subject = 1:1:7
    
%     finding max
    max_not_nb0_aut(subject) = max(mean_nb0_notarget{subject});
    max_not_nb0_manual(subject) = max(mean_nb0_notarget_manual{subject});
    max_not_nb2_aut(subject) = max(mean_nb2_notarget{subject}); 
    if subject == 2
    max_not_nb2_manual(subject) = max(mean_nb2_notarget_manual{subject}(1500:end));
    else 
    max_not_nb2_manual(subject) = max(mean_nb2_notarget_manual{subject});
    end
%     indexing
    max_index_not_nb0_aut(subject) = find(mean_nb0_notarget{subject}==max_not_nb0_aut(subject));
    max_index_not_nb0_manual(subject) = find(mean_nb0_notarget_manual{subject}==max_not_nb0_manual(subject));
    max_index_not_nb2_aut(subject) = find(mean_nb2_notarget{subject}==max_not_nb2_aut(subject));
    max_index_not_nb2_manual(subject) = find(mean_nb2_notarget_manual{subject}==max_not_nb2_manual(subject));

    
  for count = 1:3
      index_not_nb0_aut{subject}(count) = max_index_not_nb0_aut(subject)-win_len*(count);
      index_not_nb0_manual{subject}(count) = max_index_not_nb0_manual(subject)-win_len*(count);
      index_not_nb2_aut{subject}(count) = max_index_not_nb2_aut(subject)-win_len*(count);
      index_not_nb2_manual{subject}(count) = max_index_not_nb2_manual(subject)-win_len*(count);
  end 
  index_not_nb0_aut{subject}(4) = max_index_not_nb0_aut(subject);
  index_not_nb0_manual{subject}(4) = max_index_not_nb0_manual(subject);
  index_not_nb2_aut{subject}(4) = max_index_not_nb2_aut(subject);
  index_not_nb2_manual{subject}(4) = max_index_not_nb2_manual(subject);
  
  index_not_nb0_aut{subject}(count+2) = max_index_not_nb0_aut(subject)+win_len;
  index_not_nb0_aut{subject} = sort(index_not_nb0_aut{subject});
  index_not_nb0_manual{subject}(count+2) = max_index_not_nb0_manual(subject)+win_len;
  index_not_nb0_manual{subject} = sort(index_not_nb0_manual{subject});
  index_not_nb2_aut{subject}(count+2) = max_index_not_nb2_aut(subject)+win_len;
  index_not_nb2_aut{subject} = sort(index_not_nb2_aut{subject});
  index_not_nb2_manual{subject}(count+2) = max_index_not_nb2_manual(subject)+win_len;
  index_not_nb2_manual{subject} = sort(index_not_nb2_manual{subject});
  
  % obtaining values for ANOVA
  
  anova_not_nb0_aut{subject} = mean_nb0_notarget{subject}(index_not_nb0_aut{subject});
  anova_not_nb0_manual{subject} = mean_nb0_notarget_manual{subject}(index_not_nb0_manual{subject});
  anova_not_nb2_aut{subject} = mean_nb2_notarget{subject}(index_not_nb2_aut{subject});
  anova_not_nb2_manual{subject} = mean_nb2_notarget_manual{subject}( index_not_nb2_manual{subject});
end 

%% ANOVA for nback target vs non target autonomous and manual driving conditions
a=[];
b=[];
group = cell(1,3);

for subject = 1:1:7
   
            a{subject}= [anova_tnb0_aut{subject}'; anova_not_nb0_aut{subject}';anova_tnb2_aut{subject}';anova_not_nb2_aut{subject}'];
            b{subject}=[anova_tnb0_manual{subject}';anova_not_nb0_manual{subject}';anova_tnb2_manual{subject}';anova_not_nb2_manual{subject}'];
            y{subject} = horzcat(a{subject},b{subject});
            reps = size(anova_not_nb2_aut{subject},2);
            [p,tbl,stats] = anova2(y{subject},reps);
end 


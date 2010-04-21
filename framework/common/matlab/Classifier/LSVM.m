classdef LSVM < ClassifierAPI
    % Latent SVM
    
    properties
        class_names
        models
        n_components  % number of component in the mixture model      
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function [pos, neg] = make_examples(Ipaths, class_ids, id)
            n_img = numel(Ipaths);
            
            w = cell(n_img, 1);
            h = cell(n_img, 1);
            O = cell(n_img, 1);
            for i=1:n_img
                info = imfinfo(Ipaths{i});
                w{i} = info.Width;
                h{i} = info.Height;
                O{i} = 0;
            end
            
            p = class_ids == id;
            pos = struct('im', Ipaths(p), 'x1', O(p), 'y1', O(p), 'x2', w(p), 'y2', h(p));
            n = class_ids ~= id;
            neg = struct('im', Ipaths(n), 'x1', O(n), 'y1', O(n), 'x2', w(n), 'y2', h(n));            
        end
        %------------------------------------------------------------------
        function models = train_model_parallel(common, index)
            tid = task_open();
                        
            n_index = length(index);
            models = cell(n_index, 1);
            
            for k = 1:n_index
                models{k} = LSVM.train_model(common.Ipaths, common.names{index(k)}, common.class_ids, common.n, index(k));
                task_progress(tid, k/n_index);
            end
            
            task_close(tid);
        end
        %------------------------------------------------------------------
        function model = train_model(Ipaths, name, class_ids, n, i)
            global TEMP_DIR HASH_PATH;
            try
              load(fullfile(TEMP_DIR, sprintf('%s_%s_final', HASH_PATH, name)));
            catch ME
                [pos, neg] = LSVM.make_examples(Ipaths, class_ids, i);

                if n>length(pos)
                    n = length(pos);
                end
                n_neg = min(length(neg), 200);

                spos = split(pos, n);
                % train root filters using warped positives & random negatives
                try
                  load(fullfile(TEMP_DIR, sprintf('%s_%s_random', HASH_PATH, name)));
                catch ME
                  models = cell(n,1);
                  for i=1:n
                    models{i} = initmodel(spos{i});
                    models{i} = train(name, models{i}, spos{i}, neg, 1, 1, 1, 1, 2^28);
                  end
                  save(fullfile(TEMP_DIR, sprintf('%s_%s_random', HASH_PATH, name)), 'models');
                end

%               % <rev 4>
%                 % merge models and train using latent detections & hard negatives
%                 try 
%                   load(fullfile(TEMP_DIR, sprintf('%s_%s_hard', HASH_PATH, name)));
%                 catch
%                   model = mergemodels(models);
%                   model = train(name, model, pos, neg(1:n_neg), 0, 0, 2, 2, 2^28, true, 0.7);
%                   save(fullfile(TEMP_DIR, sprintf('%s_%s_hard', HASH_PATH, name)), 'model');
%                 end
% 
%                 % add parts and update models using latent detections & hard negatives.
%                 try 
%                   load(fullfile(TEMP_DIR, sprintf('%s_%s_parts', HASH_PATH, name)));
%                 catch
%                   for i=1:n
%                     model = addparts(model, i, 6);
%                   end 
%                   % use more data mining iterations in the beginning
%                   model = train(name, model, pos, neg(1:n_neg), 0, 0, 1, 4, 2^30, true, 0.7);
%                   model = train(name, model, pos, neg(1:n_neg), 0, 0, 6, 2, 2^30, true, 0.7, true);
%                   save(fullfile(TEMP_DIR, sprintf('%s_%s_parts', HASH_PATH, name)), 'model');
%                 end
%               % </rev 4>
                % <rev 5>
                model = mergemodels(models);
                for i=1:n
                  model = addparts(model, i, 6);
                end    
                % </rev 5>

                % update models using full set of negatives.
                try 
                  load(fullfile(TEMP_DIR, sprintf('%s_%s_mine', HASH_PATH, name)));
                catch ME
                  % <rev 5>
                  model = train(name, model, pos, neg, 0, 0, 1, 4, 2^30, true, 0.7);
                  model = train(name, model, pos, neg, 0, 0, 4, 1, 2^30, true, 0.7, true, ...
                                0.003*model.numcomponents, 2);                  
                  % </rev 5>
                            
                  % <rev 4>
%                   model = train(name, model, pos, neg, 0, 0, 4, 1, 2^30, true, 0.7, true, ...
%                                 0.003*model.numcomponents, 2);
                  % </rev 4>
                  save(fullfile(TEMP_DIR, sprintf('%s_%s_mine', HASH_PATH, name)), 'model');
                end

                % train bounding box prediction
                model = trainbox(name, model, pos, 0.7);
                save(fullfile(TEMP_DIR, sprintf('%s_%s_final', HASH_PATH, name)), 'model');
            end
        end
        
        %------------------------------------------------------------------
        function scores = classify_parallel(Ipaths, models)
            tid = task_open();
                        
            n_img = length(Ipaths);
            n_classes = length(models);
            scores = ones(n_img,n_classes)*(-Inf);
            
            bb_scale = 1.5;
            for i = 1:n_img;
                im = imread(Ipaths{i});
                [h w d] = size(im);
                person_box = [w/2*(1-1/bb_scale) h/2*(1-1/bb_scale) w/2*(1+1/bb_scale) h/2*(1+1/bb_scale)];
                for j = 1:n_classes
                    boxes = detect(im, models{j}, -Inf); %models{j}.thresh);
                    if ~isempty(boxes)
                      overlap = inter_box(person_box, boxes(:, 1:4));
                      min_over = 0.6;
                      while isempty(find(overlap>=min_over,1))
                          isempty(find(overlap>=min_over,1))
                          min_over = min_over - 0.1;
                      end
                      I = (overlap>=min_over);
                      scores(i,j) = max(boxes(I,end));   
                    end
                end            
                task_progress(tid, i/n_img);
            end    
            
            scores = scores';
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function box = detect_parallel(im, models)
            tid = task_open();
            
            n_models = size(models,1);
            box = cell(n_models, 2);
            
            for i = 1:n_models
                b = detect(im, models{i}, -Inf);
                if ~isempty(b)
                    [m I] = max(b(:,end));
                    box{i,1} = b(I,:);
                    box{i,2} = m;
                else
                    box{i,1} = [];
                    box{i,2} = -Inf; 
                end
            end       
            task_close(tid);
        end               
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = LSVM(n_components)
            obj = obj@ClassifierAPI([]);
            obj.n_components = n_components;
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function cross_validation = learn(obj, root)
            global TEMP_DIR HASH_PATH USE_PARALLEL;
            [Ipaths labels] = get_labeled_files(root, 'Loading training set...\n');
            [class_ids names] = names2ids(labels);
            obj.class_names = names;
            
            n_classes = length(obj.class_names);
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, obj.toFileName()));

            if exist(file, 'file') == 2
                load(file, 'lsvm_models');                
                obj.models = lsvm_models;
                write_log(sprintf('Classifier loaded from cache: %s.\n', file));
            else
                if USE_PARALLEL
                    common = struct('Ipaths', [], 'names', [], 'class_ids', class_ids, 'n', obj.n_components);
                    common.Ipaths = Ipaths;
                    common.names = obj.class_names;
                    lsvm_models = run_in_parallel('LSVM.train_model_parallel', common, [1:n_classes]', 0, 0);
                else
                    lsvm_models = cell(n_classes, 1);
                    for k = 1:n_classes
                        lsvm_models{k} = LSVM.train_model(Ipaths, obj.class_names{k}, class_ids, obj.n_components, k);
                    end
                end
                save(file, 'lsvm_models');
                obj.models = lsvm_models;
            end
                
            cross_validation = [];
        end
        
        %------------------------------------------------------------------
        % Classify the testing pictures
        function [Ipaths classes correct_label assigned_label scores] = classify(obj, Ipaths, correct_label)
            global USE_PARALLEL;
            
            classes = obj.class_names;
            n_classes = size(classes, 1);
            
            if nargin < 3
                [Ipaths l] = get_labeled_files(Ipaths, 'Loading testing set...\n');
                correct_label = names2ids(l, classes);    
            end
            n_img = length(Ipaths);
                    
            pg = ProgressBar('Classifying', 'Computing bounding boxes...');
             
            if USE_PARALLEL
                scores = run_in_parallel('LSVM.classify_parallel', Ipaths, obj.models, 0, 0, pg, 0, 1)';
            else
                scores = ones(n_img,n_classes)*(-Inf); 
                bb_scale = 1.5;
                for i = 1:n_img;
                    im = imread(Ipaths{i});
                    [h w d] = size(im);
                    
                    person_box = [w/2*(1-1/bb_scale) h/2*(1-1/bb_scale) w/2*(1+1/bb_scale) h/2*(1+1/bb_scale)];
                    for j = 1:n_classes
                        boxes = detect(im, obj.models{j}, -Inf); %models{j}.thresh);
                        if ~isempty(boxes)
                          overlap = inter_box(person_box, boxes(:, 1:4));
                          min_over = 0.6;
                          while isempty(find(overlap>=min_over,1))
                              isempty(find(overlap>=min_over,1))
                              min_over = min_over - 0.1;
                          end
                          I = (overlap>=min_over);
                          scores(i,j) = max(boxes(I,end));   
                        end
                    end                
                    pg.progress(i/n_img);
                end    
            end

            assigned_label = zeros(n_img,1); 
            for i = 1:n_img
                [m, j] = max(scores(i,:));
                assigned_label(i) = j;
            end
            
            pg.close();
        end
        
        %------------------------------------------------------------------
        % Classify the given picture
        function boxes = classify_and_get_boxes(obj, Ipath, visu)
            global USE_PARALLEL;
            
            if nargin < 3
                visu = 0;
            end
            classes = obj.class_names;
            n_classes = size(classes, 1);
            
            scores = ones(1,n_classes)*(-Inf);
            box = cell(1,n_classes);
            
            im = imread(Ipath);
            if USE_PARALLEL
                box = run_in_parallel('LSVM.detect_parallel', im, obj.models, 0, 0);
                [m, i] = max([box{:,2}]);
                boxes = box{i,1};
            else
                for i = 1:n_classes
                    b = detect(im, obj.models{i}, -Inf);
                    if ~isempty(b)
                        [m I] = max(b(:,end));
                        scores(i) = m;
                        box{i} = b(I,:);
                    else
                        box{i} = [];
                    end
                end            

                [m, i] = max(scores);
                boxes = box{i};
            end
            
            fprintf('Image assigned to %s\n', classes{i});           
            
            if visu
                showboxes(im, boxes);
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('LSVM (%d components)', obj.n_components);
        end
        function str = toFileName(obj)
            str = sprintf('LSVM[%d]', obj.n_components);
        end
        function str = toName(obj)
            str = sprintf('LSVM(%d)', obj.n_components);
        end
    end    
end

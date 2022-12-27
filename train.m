training_faces = [data_directory, '/', 'training_faces'];
training_nonfaces = [data_directory, '/', 'training_nonfaces'];
training_dimensions = [training_faces, '/', '2463d171.bmp'];

%%

%face = convertCharsToStrings(training_dimensions);

% figure();
%imshow(face)
%[J, rect] = imcrop(face)

% Using the commented out code above, it displays the face and allows you
% to crop it manually, the crop dimension/location is returned as an array,
% the array i made is the one i put into the crop below

% cropped_face = imcrop(face,[20.5100   30.5100   61.9800   58.9800]);
% [rows_face, cols_face] = size(cropped_face);

rows_face = 59;
cols_face = 62;

folder = convertCharsToStrings(training_faces);
imagefiles = dir(folder);      
nfiles = length(imagefiles);    % Number of files found

cropped_faces = uint8(zeros(rows_face, cols_face, nfiles));

ds = imageDatastore(folder);

for i = 1:nfiles - 3
    % read image from datastore
    img = read(ds);             
    cropped_faces(:,:,i) = imcrop(img,[20.5100   30.5100   61.9800   58.9800]);
end
%%
% STEP 2: take subimages of training_nonfaces that are the size of
% training_faces

non_face_folder = convertCharsToStrings(training_nonfaces);

ds = imageDatastore(non_face_folder);
imagefiles2 = dir(non_face_folder);      
nfiles2 = length(imagefiles2);    % Number of files found

nonfaces = uint8(zeros(rows_face, cols_face, nfiles2)); 

counter = 1;

while hasdata(ds) 
    % read image from datastore
    img = rgb2gray(read(ds));             
    [rows_img, cols_img] = size(img);

    for i = 1:rows_face:(rows_img - rows_face)
        for j = 1:cols_face:(cols_img - cols_face)
            window = img(i:(i+rows_face-1), j:(j+cols_face-1));
            nonfaces(:, :, counter) = uint8(window);
            counter = counter + 1;
        end
    end
end

%%
% STEP 3: find the integral image of each face and non-face 

cropped_faces = uint16(cropped_faces);
nonfaces = uint16(nonfaces);

face_integrals = zeros(rows_face,cols_face,nfiles);

for i = 1:nfiles
    face_integrals(:,:,i) = integral_image(cropped_faces(:,:,i));
end

nonface_integrals = zeros(rows_face,cols_face,nfiles2);

for i = 1:counter - 1
    nonface_integrals(:,:,i) = integral_image(nonfaces(:,:,i));
end

%%
% STEP 4: find weak classifiers

number = 5000; %% Changed after experimentation. Good error rate with faster training
weak_classifiers = cell(1, number);
for i = 1:number
    weak_classifiers{i} = generate_classifier(rows_face, cols_face);
end

%%

example_number = size(cropped_faces, 3) + size(nonfaces, 3);
labels = zeros(example_number, 1);
labels (1:size(cropped_faces, 3)) = 1;
labels((size(cropped_faces, 3)+1):example_number) = -1;
examples = zeros(rows_face, cols_face, example_number);
examples (:, :, 1:size(cropped_faces, 3)) = face_integrals;
examples(:, :, (size(cropped_faces, 3)+1):example_number) = nonface_integrals;

classifier_number = numel(weak_classifiers);

responses =  zeros(classifier_number, example_number);

for example = 1:example_number
    integral = examples(:, :, example);
    for feature = 1:classifier_number
        classifier = weak_classifiers {feature};
        responses(feature, example) = eval_weak_classifier(classifier, integral);
    end
    disp(example);
end

%%
% choose a classifier
a = random_number(1, classifier_number);
wc = weak_classifiers{a};

% choose a training image
b = random_number(1, example_number);
if (b <= size(cropped_faces, 3))
    integral = face_integrals(:, :, b);
else
    integral = nonface_integrals(:, :, b - size(cropped_faces,3));
end

% see the precomputed response
disp([a, b]);
disp(responses(a, b));
disp(eval_weak_classifier(wc, integral));

%%
weights = ones(example_number, 1) / example_number;
%%

cl = random_number(1, 5000);
[error, thr, alpha] = weighted_error(responses, labels, weights, cl)

%% AdaBoost Implementation

boosted_classifier = AdaBoost(responses, labels, 15);

save boostedVariables
%%
% load boostedClass.mat;
load boostedVariables.mat

%% Boostrapping

% missed_integral = zeros(rows_face,cols_face,length(missed_num));

% for i = 1:length(missed_num)
%     missed_integral(:,:,i) = examples(:,:,missed_num(i));
% end


% length(missed_num)
% new_responses =  zeros(classifier_number, length(missed_num)+1);
% new_examples = zeros(rows_face, cols_face, length(missed_num));

% for i = 1:length(missed_num)
%     new_examples(:,:,i) = examples(:,:,missed_num(i));
% end

% for example2 = 1:length(missed_num)
%     integral = new_examples(:, :, example2);
%     for feature = 1:classifier_number
%         classifier = weak_classifiers {feature};
%         new_responses(feature, example2) = eval_weak_classifier(classifier, integral);
%     end
% end
% 
% boosted_classifier = AdaBoost(new_responses, labels, 15);

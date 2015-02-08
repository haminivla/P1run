# runAnalysis Readme
## Course Project for Getting and Cleaning Data subject
This readme file describes how the script 'runAnalysis.R' works.  
The data source comes from the Samsung dataset found at this [link](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones).  

### Requirements  
A quick background introduction on the requirements for this script are:  
1. Merges the training and the test sets to create one data set  
2. Extracts only the measurements on the mean and standard deviation for each measurement.  
3. Uses descriptive activity names to name the activities in the data set  
4. Appropriately labels the data set with descriptive variable names.  
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

### 1. Merge
First, all necessary data files are read using the following code. Inertia signals data are ignored since they are not required in the analysis.
```
features <- readLines("features.txt")  
labels <- readLines("activity_labels.txt")  
x.test <- read.table("test/X_test.txt")  
y.test <- fread("test/y_test.txt")  
sub.test <- fread("test/subject_test.txt")  
x.train <- read.table("train/X_train.txt")  
y.train <- fread("train/y_train.txt")  
sub.train <- fread("train/subject_train.txt")
```
As I find it faster and more convenient to perform **step 3** (Labeling the activities) at this stage before combining the data sets, let's work on our activities' labels.  
The activities are referenced by their index numbers in 'y.test' and 'y.train'. Let's convert them to characters now for easier data manipulation later.
```
y.test <- as.data.table(lapply(y.test, as.character))  
y.train <- as.data.table(lapply(y.train, as.character))  
```
Next, 'labels' which contains the human readable labels are cleaned by removing the index digit, space and underscore.
```
labels <- substr(labels, 3, nchar(labels))  
labels <- gsub("*_", " ", labels)  
```
Since the labels in vector 'labels' are correctly ordered according to their index, we can use a for loop to copy the appropriate labels to the rows with corresponding index number in 'y.test' and 'y.train'.
```
for(i in 1:length(labels)) { y.test[V1==i] <- labels[i] }  
for(i in 1:length(labels)) { y.train[V1==i] <- labels[i] }  
```
Add new columns to the test and train data sets with subjects' index (sub.test and sub.train) and labels (y.test and y.train). Finally, append the rows of data in 'train' to 'test' and form a new data set 'merged'.
```
test <- cbind(sub.test, y.test, x.test)  
train <- cbind(sub.train, y.train, x.train)  
merged <- rbind(test, train)  
```

### 2. Extract mean and standard deviation for each measurement  
The strategy applied here is to look for any variables with the word 'mean' and 'std'. Note that the match is case sensitive as we want to weed out the Angle functions which also contains 'Mean' and 'Std'. A 'toMatch' vector is created and it will also include the first two columns 'Subjects' and 'Activities', as we still need them.
```
toMatch <- c("Subjects", "Activities", "mean", "std")  
```
Next, we use grep to help us hunt for the matching words in the column names of the 'merged' data set.  
```
columns <- grep(paste(toMatch, collapse="|"), colnames(merged), ignore.case=F)
```
Finally, we pick the columns matched from the 'merged' data set and copy them to a new data set 'filtered'.
```
filtered <- merged[, columns, with=FALSE]
```

### 3. Name the activities  
As described, this has been performd in step 1.  

### 4. Label variable names  
To make the variable names more human readable, the following changes were applied:  
* Removed all brackets ()  
* Replaced "t" with "time-" to describe this is a time reading  
* Replaced "f" with "freq-" to describe this is a frequency reading  
* Removed all blank spaces.  
Note that the column names 'Subjects' and 'Activities' have to be added back to the front of the vector in order.
```
features <- sub("()", "", fixed=T, features)  
features <- sub("t", "time-", fixed=T, features)  
features <- sub("f", "freq-", fixed=T, features)  
features <- sub(".* ", "", fixed=F, features)  
features <- append(features, c("Subjects", "Activities"), 0)  
suppressWarnings(colnames(merged) <- features)  
```

### 5. Average of each activity and subject
To get the average by subjects and activities, we use aggregate and apply the mean function. Note that the 'Subjects' and 'Activities' columns are no longer relevant and the correct results are in the columns 'Group.1' and 'Group.2'. Therefore, we remove the irrelevant columns and renamed the correct columns appropriately.
```
average <- suppressWarnings(aggregate(filtered, by=list(filtered$Subjects,filtered$Activities), FUN=mean))  
average$Subjects <- average$Activities <- NULL  
setnames(average, old=c("Group.1", "Group.2"), new=c("Subjects", "Activities"))  
```
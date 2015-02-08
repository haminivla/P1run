run_analysis <- function() {
	
	library(data.table)

	## Read all necessary files
	features <- readLines("features.txt")
	labels <- readLines("activity_labels.txt")
	x.test <- read.table("test/X_test.txt")
	y.test <- fread("test/y_test.txt")
	sub.test <- fread("test/subject_test.txt")
	x.train <- read.table("train/X_train.txt")
	y.train <- fread("train/y_train.txt")
	sub.train <- fread("train/subject_train.txt")

	## Map activity labels to y.test and y.train
	y.test <- as.data.table(lapply(y.test, as.character))
	y.train <- as.data.table(lapply(y.train, as.character))
	labels <- substr(labels, 3, nchar(labels))
	labels <- gsub("*_", " ", labels)
	for(i in 1:length(labels)) { y.test[V1==i] <- labels[i] }
	for(i in 1:length(labels)) { y.train[V1==i] <- labels[i] }
	
	## Merge activities(y) and subjects as new columns then merge both test and train data tables
	test <- cbind(sub.test, y.test, x.test)
	train <- cbind(sub.train, y.train, x.train)
	merged <- rbind(test, train)

	## Set column names for the variables
	features <- sub("()", "", fixed=T, features)
	features <- sub("t", "time-", fixed=T, features)
	features <- sub("f", "freq-", fixed=T, features)
	features <- sub(".* ", "", fixed=F, features)
	features <- append(features, c("Subjects", "Activities"), 0)
	suppressWarnings(colnames(merged) <- features)

	## Clean the dataset by taking only variables with 'mean' and 'std'
	toMatch <- c("Subjects", "Activities", "mean", "std")
	columns <- grep(paste(toMatch, collapse="|"), colnames(merged), ignore.case=F)
	filtered <- merged[, columns, with=FALSE]

	## Aggregate by Activities and Subjects
	average <- suppressWarnings(aggregate(filtered, by=list(filtered$Subjects,filtered$Activities), FUN=mean))
	average$Subjects <- average$Activities <- NULL
	setnames(average, old=c("Group.1", "Group.2"), new=c("Subjects", "Activities"))
	
	## Write to txt file
	write.table(average, file="run_analysis.txt", row.name=FALSE)
}

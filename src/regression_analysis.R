# This is implementation of linear/logistic regression analysis to build prediction models
# based on FB likes of users vs corresponding psyhometric traits. This models will allow
# to predict psychometric traits of users taking as input their FB likes.

source('./src/config.R')
source('./src/utils.R')

# Make sure that SVD and ROCR libraries installed
library(irlba)

# Check that input data exist
print("Checking that input data files exist")
assertthat::assert_that(file.exists(users_prdata_file))
assertthat::assert_that(file.exists(ul_prdata_file))

# 
# Load data
load(users_prdata_file)
cat(sprintf("%12s : [%d, %d]\n","Users", dim(users)[1], dim(users)[2]))
load(ul_prdata_file)
cat(sprintf("%12s : [%d, %d]\n", "Users-Likes", dim(M)[1], dim(M)[2]))

# set random number generator's seed - so results will be stable from run to run
set.seed(44)

#
# Prepare parameters for regression analysis
rVars <- colnames(users[,-1]) # the variables to predict
folds <- sample(1:n_folds, size = nrow(users), replace = TRUE) # the data samples folds for cross-validation

# Fill predictions list with NA
predictions <- list()
for(var in rVars) {
  predictions[[var]] <- rep(NA, n = nrow(users))
}

#
# Do cross-validated predictions
for(i in 1:n_folds) {
  print(sprintf("Cross-validated prediction, fold: %d", i))
  test <- folds == i # select test samples
  
  # do SVD rotation
  Msvd <- irlba(M[!test, ], nv = K)
  likesSVDrot <- unclass(varimax(Msvd$v)$loadings) # varimax rotated likes per SVD dimensions
  usersSVDrot <- as.data.frame(as.matrix(M %*% likesSVDrot))
  
  for(var in rVars) {
    predictions[[var]][test] <- linear.fit.predict(response = users, column = var, data = usersSVDrot, testFold = test)
    print(sprintf("Model for variable [%s] complete", var))
  }
  cat("\n***\n")
}

#
# Find accuracies for all predicted variables
print("Prediction accuracies")
cat("Prediction accuracies:\n", file = regr_pred_accuracy_file)
accuracies <- list()
for(var in rVars) {
  accuracies[[var]] = accuracy(users[,var], predictions[[var]])
  cat(sprintf("%9s : %.2f%%\n", var, (accuracies[[var]][[1]] * 100.0)))
  cat(sprintf("%9s : %.2f%%\n", var, (accuracies[[var]][[1]] * 100.0)), file = regr_pred_accuracy_file, append = TRUE)
}




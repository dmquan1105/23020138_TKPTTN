options(repos = c(CRAN = "https://cloud.r-project.org"))
# install.packages("tidymodels")
library("tidymodels")
data <- read.csv('mlc_churn.csv')
?mlc_churn
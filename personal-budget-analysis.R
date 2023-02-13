library(ggplot2)
library(lubridate)
library(tidyverse)



# ============================================================================== 
# pre-processing the first data set
# ==============================================================================

# setwd("C:/Users/mylen/OneDrive/Изображения/Документы/GitHub/personal-budget-analysis")

bankdata_raw <- read.csv("bank-statement.csv", sep = ',')

# fill empty date cells 
for (i in 1:nrow(bankdata_raw)) {
  if(bankdata_raw$Date[i] == '' | bankdata_raw$Date[i] == 'Date' | bankdata_raw$Date[i] == 'Your transactions') {
    bankdata_raw$Date[i] <- bankdata_raw$Date[i-1]
  }
}

# delete blank and auxiliary rows
bankdata <- subset(bankdata_raw, Description != '' & Description != 'Description' & Paid.out.... != '', select = -c(Type, Paid.in....))

# rename cols
colnames(bankdata) <- c('date', 'description', 'paidout')

# remove £ character
bankdata$paidout <- gsub("£", "", as.character(bankdata$paidout))

# lower case for description
bankdata$description <- tolower(bankdata$description)

# data format for date column
lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C")
bankdata$date <- as.Date(bankdata$date, "%d %b")
Sys.setlocale("LC_TIME", lct)

# December 2022 was occasionally labeled 2023 by R. fixing it
for (i in 1:nrow(bankdata)) {
  if(grepl("2023.12", as.character(bankdata$date[i]))){
    year(bankdata$date[i]) <- 2022
  }
}

# reorder rows ascending date
bankdata <- bankdata[order(bankdata$date),]

# make money amounts numeric
bankdata$paidout <- as.numeric(bankdata$paidout)


# ============================================================================== 
# pre-processing the second data set
# ==============================================================================

revolutdata <- read.csv("transactions_history1.csv", sep = ',')

# delete blank and auxiliary rows
revolutdata <- subset(revolutdata, State != 'Failed' & State != "Declined" & Amount != 0.00, select = -c(Type, State))

# rename cols
colnames(revolutdata) <- c('date', 'description', 'paidout')

# lower case for description
revolutdata$description <- tolower(revolutdata$description)

# delete pay ins. make pay outs positive
revolutdata <- subset(revolutdata, paidout < 0)
revolutdata$paidout <- abs(revolutdata$paidout)

# date format
revolutdata$date <- as.Date(revolutdata$date, "%Y-%m-%d")


# ============================================================================== 
# compound of two data sets
# ==============================================================================

totaldata <- rbind(revolutdata, bankdata)

# ============================================================================== 
# analysis
# ==============================================================================

# 1) food expense 

home_food_key <- c("lidl gb partick", "tesco stores", "toogoodtog", "aldi", "sainsburys")
home_food_key_pattern <- paste(home_food_key, collapse = '|')

totaldata$caterogy[grepl(home_food_key_pattern, totaldata$description)] <- "home food"

totaldata_homefood <- subset(totaldata, caterogy == "home food")

# sum of home food expense by month
totaldata_homefood_bymonth <- as.data.frame( totaldata_homefood  %>% 
  group_by(month = floor_date(date, 'month')) %>%
  summarize(sum_of_expenses = sum(paidout)) )

# delete Feb as it isn't complete yet
totaldata_homefood_bymonth <- totaldata_homefood_bymonth[-c(5),]

# format date
totaldata_homefood_bymonth$month <- format(totaldata_homefood_bymonth$month, "%m-%Y")

# plotting my monthly food expense
totaldata_homefood_bymonth$month <- factor(totaldata_homefood_bymonth$month, levels = totaldata_homefood_bymonth$month)

plot_food_bymonth <- ggplot(totaldata_homefood_bymonth, aes(month, sum_of_expenses)) +
  geom_bar(stat = "identity") +
  geom_hline(aes(yintercept = mean(sum_of_expenses)))


# 2) nicotine expense 

totaldata$caterogy[totaldata$paidout == 5.50 | totaldata$paidout == 11.00 | totaldata$paidout == 6.57 | totaldata$paidout == 13.14 | totaldata$paidout == 7.99] <- "nicotine"

totaldata_nicotine <- subset(totaldata, caterogy == "nicotine")

# sum of home food expense by month
totaldata_nicotine_bymonth <- as.data.frame( totaldata_nicotine  %>% 
             group_by(month = floor_date(date, 'month')) %>%
             summarize(sum_of_expenses = sum(paidout)) )

# format date
totaldata_nicotine_bymonth$month <- format(totaldata_nicotine_bymonth$month, "%m-%Y")


# =============== dependencies between nicotine and food expenses ==============

# compound two tables
food_and_nicotine <- cbind(totaldata_homefood_bymonth, totaldata_nicotine_bymonth)
food_and_nicotine <- food_and_nicotine[, -c(3)]
colnames(food_and_nicotine) <- c('month', 'food', 'nicotine')

dependence_plot <- ggplot(food_and_nicotine, aes(food, nicotine)) + 
  geom_point() +
  geom_smooth()


# 3) transport expense 

transport_key <- c("subway", "first glasgow", "mcgill", "tfl travel ch")
transport_key_pattern <- paste(transport_key, collapse = '|')

totaldata$caterogy[grepl(transport_key_pattern, totaldata$description)] <- "transport"



library(ggplot2)

# ============================================================================== 
# pre-processing 
# ==============================================================================

bankdata_raw <- read.csv("bank-statement.csv", sep = ',')

# fill empty date cells 
for (i in 1:nrow(bankdata_raw)) {
  if(bankdata_raw$Date[i] == '' | bankdata_raw$Date[i] == 'Date' | bankdata_raw$Date[i] == 'Your transactions') {
    bankdata_raw$Date[i] <- bankdata_raw$Date[i-1]
  }
}

# delete blank and auxiliary rows
bankdata <- subset(bankdata_raw, Description != '' & Description != 'Description', select = -c(Type))

# rename cols
colnames(bankdata) <- c('date', 'description', 'paidin', 'paidout')

# remove £ character
bankdata$paidin <- gsub("£", "", as.character(bankdata$paidin))
bankdata$paidout <- gsub("£", "", as.character(bankdata$paidout))

# lower case for description
bankdata$description <- tolower(bankdata$description)

# data format for date column
class(bankdata$date)
lct <- Sys.getlocale("LC_TIME")
bankdata$date <- as.Date(bankdata$date, "%d %b")
bankdata$date <- format(bankdata$date, "%d-%m-%Y") 

# reorder rows ascending date
bankdata <- bankdata[order(bankdata$date),]

?regexec
grepl("2023.11", as.character(bankdata$date[62]))

bankdata$date[63] <- format(bankdata$date[63], "2022-%m-%d")

# ============================================================================== 
# analysis
# ==============================================================================

# 1) food expense 

food_key <- ("lidl gb partick", )
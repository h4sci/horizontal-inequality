#'
#' Data preparation: ISO and phase
#'

# Get data
raw_data <- read.csv("raw-data/master_data.csv")

# ---------------------------------------------------------------------------
# Add ISO of country to df
# ---------------------------------------------------------------------------

raw_data$ISO <- NA

for (i in 1:nrow(raw_data)){
  if (raw_data[i,"country"] %in% world_ext$name_long){
  raw_data[i,which(colnames(raw_data)== "ISO")] <- world_ext[which(world_ext$name_long == raw_data[i,"country"]),"iso_a3"]

    }else if(raw_data[i,"country"] %in% world_ext$country){
      raw_data[i,which(colnames(raw_data)== "ISO")] <- world_ext[which(world_ext$country == raw_data[i,"country"]),"iso_a3"]
    
  } else {raw_data[i,which(colnames(raw_data)== "ISO")] <- NA}
  
}

# Add remaining countries manually

country_NA <- raw_data[which(is.na(raw_data$ISO)),"country"]

raw_data[which(raw_data$country == "Ivory Coast"),"ISO"]<- "CIV"
raw_data[which(raw_data$country == "Sao Tome"),"ISO"]<- "STP"
raw_data[which(raw_data$country == "Kyrgyz"),"ISO"]<- "KGZ"
raw_data[which(raw_data$country == "Timor Leste"),"ISO"]<- "TLS"
raw_data[which(raw_data$country == "Dominican"),"ISO"]<- "DOM"

# ---------------------------------------------------------------------------
# Add phase of survey to df
# ---------------------------------------------------------------------------

raw_data$phase <- NA

for (i in 1:nrow(raw_data)){
  if(raw_data[i,"year"] %in% c(1984,1985,1986,1987)){
    raw_data[i,"phase"] <- 1
  } else if (raw_data[i,"year"] %in% c(1988,1889,1990,1991)){
    raw_data[i,"phase"] <- 2
  } else if (raw_data[i,"year"] %in% c(1992,1993,1994,1995,1996)){
    raw_data[i,"phase"] <- 3
  }else if (raw_data[i,"year"] %in% c(1997,1998,1999,2000,2001,2002)){
    raw_data[i,"phase"] <- 4
  } else if (raw_data[i,"year"] %in% c(2003,2004,2005,2006,2007)){
    raw_data[i,"phase"] <- 5
  } else if (raw_data[i,"year"] %in% c(2008,2009,2010,2011,2012)){
    raw_data[i,"phase"] <- 6
  } else {
    raw_data[i,"phase"] <- 7
  }
}

write.csv(raw_data,"raw-data/master_data_ISO_phase.csv")


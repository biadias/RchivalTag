
resample_TS <- function(df, tstep){
  tsims <- list()
  tstep0 <- tstep
  min_tstep <- unique(as.numeric(diff(df$date.long[1:10]))) #"corresponds to raw data sets!"
  if(tstep %% min_tstep != 0) stop('selected time step (',tstep,'s)is not a multiple of the original sampling resolution (',min_tstep,'s). Please revise!')
  if(tstep == 0) tstep0 <- min_tstep
  
  df$date.long <- as.POSIXct(df$date.long,tz = 'UTC')
  df$date <- as.Date(df$date.long)
  df$year <- as.numeric(format(df$date, "%Y"))
  df$month <- as.numeric(format(df$date, "%m"))
  df$day <- as.numeric(format(df$date, "%d"))
  df$tstep <- tstep0

  tstarts <- which(df$date.long < df$date.long[1]+tstep0)
  tag <- paste(df[1,which(names(df) %in% c('Serial','tag',"Ptt","DeployID"))],collapse=" - ")
  # head(df)
  tstart <- tstarts[1]
  for(tstart in tstarts){
    cat('resampling time series data from tag',tag,'with time step', tstep, 's - repetition',tstart,"of", tail(tstarts,1),'\n')
    ii <- which(as.character(df$date.long) %in% as.character(seq(df$date.long[tstart],df$date.long[nrow(df)],by=tstep0)))
    ts <- df[ii,]
    tsims[[tstart]] <- ts
  }
  return(tsims)
}
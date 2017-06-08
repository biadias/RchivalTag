###' todo:
#' merge histos -> seperate function. allow user to select new bins (omit individuals that do not have these bin breaks)


read_histos <- function(hist_file){
  hist_dat <- NULL
  if(is.character(hist_file)) hist_dat <- read.table(hist_file, header = TRUE, sep = ",")
  if(is.data.frame(hist_file)) hist_dat <- hist_file
  if(is.null(hist_dat)) stop('Provided hist_file not in allowed formats (data.frame or character string indicating the name of the file to read). Please revise.')
  identifiers <- c('Serial',"DeployID",'Ptt')
  identifiers <- identifiers[which(identifiers %in% names(hist_dat))]
  head(hist_dat)
  
  ID <- c()
  for(id in identifiers){
    ID <- paste(ID, paste(id,hist_dat[[id]],sep="."),sep=.switch_if(id==identifiers[1],'','_'))
  }
  hist_dat <- data.frame(ID=ID,hist_dat,stringsAsFactors = F)
  
  hist_list <- list()
  for(Type in c('TAD','TAT')){
    
    raw_limits <- hist_dat[which(hist_dat$HistType == paste0(Type,"LIMITS")),]
    bin_cols <- which(names(hist_dat) == 'Bin1'):ncol(hist_dat)
    limits <-  plyr::ddply(raw_limits,c("ID",identifiers),function(x) {
      for(i in bin_cols) {
        if(grepl(">",x[,i])) x[,i] <- .switch_if(Type == "TAD",5000,45)
        x[,i] <- .fact2num(x[,i]) 
      }
      #   bin.cols <- grep("Bin",names(hist_dat))
      n <- which(!is.na(x[,bin_cols]))
      c(bin_breaks= paste(x[,bin_cols[n]],collapse="; "),
        nbins=length(n))
    })
    
    ### check if identifiers are ok!
    check_limits <-  plyr::ddply(limits, identifiers,function(x)c(occasions=nrow(x)))
    if(any(check_limits$occasions > 1)){
      stop("multiple ",  paste0(Type,"LIMITS"), " found for an unique ",  .switch_if(length(identifiers) > 1, "combination of ","identifier "),paste(identifiers,collapse=", "),
           ". Consider to add column 'Serial' in input dataframe.\n", 
           .print_df(check_limits))
    }
    
    id <- ID[1]
    for(id in unique(ID)){
      ii <- which(limits$ID == id)
      if(length(ii) == 0){
        warning("No tad limits (break points) found for tag: ", gsub('\\.',' ',gsub("_"," - ",id)),"\nThis tag was skipped!")
      }else{
        hist_list[[Type]][[id]]$bin_breaks <- bb <- as.numeric(strsplit(limits$bin_breaks[ii],'; ')[[1]])
        add0 <- hist_dat[which(hist_dat$ID == ID & hist_dat$HistType == Type),]
        add0$date.long <- strptime(as.character(add0$Date),'%H:%M:%S %d-%b-%Y')
        if(any(is.na(add0$date.long))) stop('Date-vector not in correct format (%H:%M:%S %d-%b-%Y)! Please revise.')
        add0$date <- as.Date(add0$date.long)
        info <- add0[,which(names(add0) %in% c(identifiers,'date','date.long'))]
        nbins <- length(bb)
        madd0 <- add0[,which(names(add0) %in% paste0("Bin",1:nbins))]
        for(ii in 1:ncol(madd0)) madd0[,ii] <- .fact2num(madd0[,ii])
        
        add_final <- .get_histos_stats(madd0,bb)
        hist_list[[Type]][[id]]$df <- data.frame(info,add_final,stringsAsFactors = F)
      }
    }
  }
  #   if(do.merge){
  #     
  #   }
  
  return(hist_list)
}


.print_df <- function(x)
{
  paste(capture.output(print(x)), collapse = "\n")
}


combine_histos <- function(hist_list1,hist_list2){
  for(Type in c('TAD','TAT')){
    nn1 <- names(hist_list1[[Type]])
    nn2 <- names(hist_list2[[Type]])
    
    sstp <- paste("Grouped or merged", Type, 'data of seperate lists can not be combined since double occurences of unique tags can not be verified. Please rerun on ungrouped or unmerged data!')
    if(any(grepl('group',nn1) | grepl('merged',nn1))) {
      warning('ungrouping hist_list1')
      hist_list1 <- unmerge_histos(hist_list1)
      nn1 <- names(hist_list1[[Type]])
    }
    if(any(grepl('group',nn2) | grepl('merged',nn2))){
      warning('ungrouping hist_list2')
      hist_list2 <- unmerge_histos(hist_list2)
      nn2 <- names(hist_list2[[Type]])
    }

    if(any(nn2 == nn1)){
      ii <- which(nn2 %in% nn1)
      wwarn <- paste(Type,'-data from tags with ids:\n',paste(nn2[ii],collapse=",\n"), '\nfound in hist_list2, existed already in hist_list1 and will be skipped.')
      options(warning.length = nchar(wwarn)+10)
      warning(wwarn)
      nn2 <- nn2[-ii]
    }
    for(n in nn2){
      hist_list1[[Type]][[n]] <- hist_list2[[Type]][[n]]
    }
  }
  return(hist_list1)
}


unmerge_histos <- function(hist_list){
  hist_list_new <- list()
  for(Type in c('TAD','TAT')){
    #     print(Type)
    nn <- names(hist_list[[Type]])
    for(n in nn){
      #       n <- nn[1]
      hist_dat <- hist_list[[Type]][[n]]$df
      identifiers <- c('Serial',"DeployID",'Ptt')
      identifiers <- identifiers[which(identifiers %in% names(hist_dat))]
      
      IDs <- c()
      for(id in identifiers){
        IDs <- paste(IDs, paste(id,hist_dat[[id]],sep="."),sep=.switch_if(id==identifiers[1],'','_'))
      }
      
      hist_dat$ID <- IDs
      for(ID in unique(IDs)){
        #         print(ID)
        #         ID <- IDs[1]
        add <- hist_dat[which(hist_dat$ID == ID),]
        add$ID <- c()
        if(ID %in% names(hist_list_new[[Type]])) stop('tag with identifier:\n', gsub('\\.',' ',gsub('_',' - ',ID)),'\nwith more than 1 occurence! Please check list manually!')
        hist_list_new[[Type]][[ID]]$df <- add
        hist_list_new[[Type]][[ID]]$bin_breaks <- hist_list[[Type]][[n]]$bin_breaks
      }
    }
  }
  return(hist_list_new)
}

rebin_histos <- merge_histos <- function(hist_list, tad_breaks=NULL, tat_breaks=NULL, force_merge=FALSE){
  hist_list_new <- list()
  Type <- 'TAD'
  for(Type in c('TAD','TAT')){
    vlim <- .switch_if(Type == "TAD",c(0,5000),c(0,45))
    IDs <- names(hist_list[[Type]])
    if(length(IDs) != 0){
      cat('\n\nmerging',Type,'data:')
      
    #       mm <- matrix(F,ncol = length(vlim[1]:vlim[2]), nrow=length(IDs))
    if(length(IDs) > 1){
      add <- c()
      for(ID in IDs){
        ID_limits <- hist_list[[Type]][[ID]]$bin_breaks
        for(ii in 1:length(ID_limits)){
          if(ii == 1 | ID_limits[ii] < vlim[1]) ID_limits[ii] <- vlim[1]
          if(ii == length(ID_limits) | ID_limits[ii] > vlim[2]) ID_limits[ii] <- vlim[2] ## setting last bin break to max(vlim)
        }
        add <- rbind(add, data.frame(ID=ID,bin_breaks= paste(ID_limits,collapse="; "),stringsAsFactors = F))
      }
      
      add.bkp <- add
      add$bin_breaks <- gsub('0; 0; ','0; ',add$bin_breaks)
      add$bin_breaks <- gsub('45; 45','45',add$bin_breaks)
      add$bin_breaks <- gsub('5000; 5000','5000',add$bin_breaks)
    }else{
      ID_limits <- hist_list[[Type]][[IDs]]$bin_breaks
      add.bkp <- add <- data.frame(ID=IDs,bin_breaks= paste(ID_limits,collapse="; "),stringsAsFactors = F)    
      if(is.null(tat_breaks) & Type == "TAT") tat_breaks <- ID_limits
      if(is.null(tad_breaks) & Type == "TAD") tad_breaks <- ID_limits  
    }    

    grouped <- plyr::ddply(add,c("bin_breaks"),function(x)c(n_tags=nrow(x),tags=paste(x$ID,collapse="; "))) ## unique unmerged bins
    cat("\nFound the following unique bin breaks for",paste0(Type,"-data:\n"),.print_df(grouped[,1:2]))
    grouped$ID <- paste0("group",1:nrow(grouped))
    
    #     if(force_merge){
    #       if(!is.null(tat_breaks)) warning('Forcing merge on all groups! Ignoring provided ')
    #     }
    
    new_breaks <- tat_breaks
    if(Type == "TAD")  new_breaks <- tad_breaks
    #     if(!is.null(new_breaks)) force_merge <- F
    
    
    ### option 1: merge groups with common bin_breaks
    if(is.null(new_breaks) & !force_merge){      
      for(j in 1:nrow(grouped)){
        IDs <- add$ID[which(add$bin_breaks == grouped$bin_breaks[j])]
        add_group <- c()
        for(ID in IDs){
          hist_dat_id <- hist_list[[Type]][[ID]]$df
          bb_id <- as.numeric(strsplit(add.bkp$bin_breaks[which(add.bkp$ID == ID)],'; ')[[1]])
          #           bb_id[2] <- 0
          info <- hist_dat_id[,which(!grepl('Bin', names(hist_dat_id)))]
          madd0 <- hist_dat_id[,grep('Bin', names(hist_dat_id))]
          
          bb_id_unique <- unique(bb_id); 
          nbbs <- length(bb_id_unique)
          madd <- madd0[,1:nbbs]; madd[,] <- NA
          for(h in 1:nbbs){
            m <- madd0[,which(bb_id == bb_id_unique[h])]
            if(is.data.frame(m)){
              madd[,h] <- rowSums(m,na.rm = T)
            }else{
              madd[,h] <- m
            }
          }
          add_id <- cbind(info,madd)
          add_group <- rbind(add_group,add_id)
        }
        hist_list_new[[Type]][[paste0("group",j)]]$df <- add_group
        hist_list_new[[Type]][[paste0("group",j)]]$bin_breaks <- bb_id_unique
      }
    }
    
    ### option 2: remerge groups with user-specified bin_breaks
    if(!is.null(new_breaks) & !force_merge){
      common_bin_breaks <- new_breaks
      bb <- strsplit(grouped$bin_breaks,'; ')
      IDs <- c()
      delete_groups <- c()
      for(bid in 1:nrow(grouped)){
        if(all(common_bin_breaks %in% as.numeric(bb[[bid]]))){
          add_IDs <- strsplit(grouped$tags[bid],'; ')[[1]]
          IDs <- c(IDs,add_IDs)
          delete_groups <- c(delete_groups,grouped$ID[bid])
        }
      }
      for(gg in delete_groups) hist_list_new[[Type]][[gg]] <- c()
      hist_list_new <- .run_merge_hists(IDs=IDs, Type, common_bin_breaks, add, add.bkp, hist_list, hist_list_new)
    }
    
    ### option 3: force merging on common bin breaks
    if(force_merge){
      if(!is.null(new_breaks)){
        common_bin_breaks <- new_breaks
        bb_ids <- strsplit(add$bin_breaks,'; ')
        warn_ids <- c()
        for(ii in 1:length(bb_ids)){
          if(!all(common_bin_breaks %in% bb_ids[[ii]])) warn_ids <- c(warn_ids, ii)
        }
        wwarn <- paste0("user-specified ",tolower(Type),'_breaks not found for tags with ID codes:\n',paste(gsub('\\.', ' ', gsub('_',' - ',add$ID[warn_ids])),collapse="\n"),'\nThese tags were omitted!')
        options(warning.length = nchar(wwarn)+10)
        warning(wwarn)
        
      }else{
        
        nn <- unique(.fact2num(unlist(strsplit(grouped$bin_breaks, '; '))))
        nn <- nn[order(nn)]
        nn
        mm <- as.data.frame(matrix(F,ncol = length(nn), nrow=length(IDs)))
        names(mm) <- paste0('bb',nn)
        oc <- data.frame(ID=IDs,mm,stringsAsFactors = F)
        #       head(oc)
        
        i <- 1
        for(i in 1:nrow(oc)){
          ID <- oc$ID[i]
          bins <- strsplit(add.bkp$bin_breaks[which(add.bkp == ID)],'; ')[[1]]
          bbs <- paste0("bb",bins)
          bb <- bbs[1]
          for(bb in bbs) oc[[bb]][i] <- T
        }
        
        common_bbs <- c()
        for(i in 2:ncol(oc)) if(all(oc[,i])) common_bbs <- c(common_bbs, names(oc)[i])
        common_bin_breaks <- as.numeric(gsub('bb','',common_bbs))
      }
      hist_list_new <- .run_merge_hists(IDs=add$ID, Type, common_bin_breaks, add, add.bkp, hist_list, hist_list_new)
    }
    hist_list[[Type]] <- hist_list_new[[Type]]    
  }
}
  return(hist_list)
}


.run_merge_hists <- function(IDs, Type, common_bin_breaks, add, add.bkp, hist_list, hist_list_new){
  cat('\nForcing merge on common', Type, 'bin_breaks:\n', common_bin_breaks)
  
  if(length(common_bin_breaks) < 3){
    warning('Less than three common bin_breaks for',paste0(Type,'-data. Can not merge!'))
  }else{
    add_all <- c()
    for(ID in IDs){
      hist_dat_id <- hist_list[[Type]][[ID]]$df
      bb_id <- as.numeric(strsplit(add.bkp$bin_breaks[which(add.bkp$ID == ID)],'; ')[[1]])
      #           bb_id[2] <- 0
      info <- hist_dat_id[,which(!grepl('Bin', names(hist_dat_id)) | names(hist_dat_id) == 'NumBins')]
      madd0 <- hist_dat_id[,which(grepl('Bin', names(hist_dat_id)) & !(names(hist_dat_id) %in% 'NumBins'))]
      
      nbbs <- length(common_bin_breaks)
      madd <- madd0[,1:nbbs]; madd[,] <- NA
      for(h in 1:nbbs){
        m <- madd0[,which(bb_id >= common_bin_breaks[h] & bb_id < c(common_bin_breaks,max(common_bin_breaks)+1)[h+1])]
        if(is.data.frame(m)){
          madd[,h] <- rowSums(m,na.rm = T)
        }else{
          madd[,h] <- m
        }
      }
      add_id <- cbind(info,madd)
      add_all <- rbind(add_all,add_id)
    }
    hist_list_new[[Type]][['merged']]$df <- add_all
    hist_list_new[[Type]][['merged']]$bin_breaks <- common_bin_breaks
  }
  return(hist_list_new)
}




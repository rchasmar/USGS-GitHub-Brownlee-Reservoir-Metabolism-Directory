metabb <- function(
  data,
  method,
  wtr.name,
  irr.name, 
  do.obs.name,
  ...
) {
    
  # Capture additional arguments
  m.args <- list(...)
    
  # Rename columns if necessary
  if (wtr.name != "wtr") {
    if (!"wtr" %in% names(
                      x = data
                    )) {
      names(
        x = data
      )[names(
          x = data
        ) == wtr.name] <- "wtr"
    } else {
        data[ , "wtr"] <- data[ , wtr.name]
      }
  }
  if (irr.name != "irr") {
    if (!"irr" %in% names(
                      x = data
                    )) {
      names(
        x = data
      )[names(
          x = data
        ) == irr.name] <- "irr"
    } else {
        data[ , "irr"] <- data[ , irr.name]
      }
  }   
  if (do.obs.name != "do.obs") {
    if (!"do.obs" %in% names(
                         x = data
                       )) {
      names(
        x = data
      )[names(
          x = data
        ) == do.obs.name] <- "do.obs"
    } else {
        data[ , "do.obs"] <- data[ , do.obs.name]
      }
  }
    
  # Define possible methods and match the provided method
  possibleMethods <- c(
                       "bookkeep",
                       "bayesian",
                       "kalman",
                       "ols",
                       "mle"
                     )
  mtd <- match.arg(
               arg = method,
           choices = possibleMethods
         )
  mtdCall <- paste(
               "metab",
               mtd,
               sep = "."
             )
    
  # Prepare data by removing rows with NAs
  data1 <- addNAs(
                       x = data[complete.cases(data), ],
             percentReqd = 1
           )
  data2 <- data1[complete.cases(data1), ]
    
  # Generate unique IDs based on year and day of year (doy)
  ids <- id(
           list(
             data2[ , "year"],
             trunc(
               x = data2[ , "doy"]
             )
           )
         )
  ids <- as.integer(
           x = ids - (min(ids) - 1)
         )
  nid <- length(
           x = unique(
                 x = ids
               )
         )
    
  # Initialize results list
  results <- vector(
                 mode = "list",
               length = nid
             )
  names(
    x = results
  ) <- unique(
         x = ids
       )
    
  # Loop through unique IDs and apply the selected method
  for (i in unique(
              x = ids
            )) {
    poss.args <- c(
                   "do.obs",
                   "do.sat",
                   "k.gas",
                   "z.mix",
                   "irr",
                   "wtr",
                   "datetime"
                 )
    used.args <- poss.args[poss.args %in% names(
                                            x = data2
                                          )]
    largs0 <- as.list(
                x = data2[i == ids, used.args]
              )
    largs <- c(
               largs0,
               m.args[!names(
                         x = m.args
                       ) %in% names(
                                x = largs0
                              )]
             )
    results[[as.character(
               x = i
             )]] <- do.call(
                      what = mtdCall,
                      args = largs
                    )
  }
    
    # Combine results into a single data frame
    answer0 <- conquerList(
                      x = results,
                 naming = data.frame(
                            year = data2[!duplicated(
                                            x = ids
                                          ), "year"],
                             doy = trunc(
                                     x = data2[!duplicated(
                                                  x = ids
                                                ), "doy"]
                                   )
                          )
               )
    a0.names <- names(
                  x = results[[1]]
                )
    
    # Process the combined results
    if (length(
          x = a0.names
        ) > 1 & is.list(
                  x = answer0
                ) & !is.data.frame(
                       x = answer0
                     )) {
      names(
        x = answer0
      ) <- a0.names
      answer <- answer0$"metab"

      for (i in 1:length(
                    x = a0.names
                  )) {
        if (a0.names[i] == "metab") {
          next
        }
        if (a0.names[i] == "smoothDO") {
          t.sDO <- answer0[[a0.names[i]]]
          t.sDO <- t.sDO[ , !names(
                               x = t.sDO
                             ) %in% c(
                                      "doy",
                                      "year"
                                    )]
          attr(
                x = answer,
            which = "smoothDO.vec"
          ) <- c(
                 t(
                   x = t.sDO
                 )
               )
        }
        attr(
              x = answer,
          which = a0.names[i]
        ) <- answer0[[a0.names[i]]]
      }
    } else {
      answer <- answer0
      }
    
    return(answer)
}

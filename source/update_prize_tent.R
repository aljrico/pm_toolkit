update_prize_tent <- function(spreadsheet_name = "(HS) Mysteryboxes", spreadsheet_tab_name = 'prizetent', game_folder = 'homestreet'){
  
  fill_gaps <- function(df){
    df <- data.table::data.table(df)
    cols <- colnames(df)
    df[, (cols) := lapply(.SD, zoo::na.locf), .SDcols = cols]
    return(data.table::data.table(df))
  }
  
  sh_name <- spreadsheet_name
  sh_tab_name <- spreadsheet_tab_name
  
  design_table <- 
    googlesheets::gs_title(sh_name) %>% 
    googlesheets::gs_read(sh_tab_name) %>% 
    fill_gaps()
  
  items_list <- 
    googlesheets::gs_title(sh_name) %>% 
    googlesheets::gs_read('items') %>% 
    data.table::data.table()
  
  
  
  
  
  
  # mysteryboxes ------------------------------------------------------------
  
  csv_location <- paste0('~/', game_folder, '/Assets/data/source/csv/prizetentmysteryboxes.csv')
  csv_link <- 'https://raw.githubusercontent.com/supersolid/spark/master/Assets/data/source/csv/prizetentmysteryboxes.csv?token=AEKOLXMZA3HL6IIQV2Z3YAS5P5XMG'
  
  original_csv <- 
    data.table::fread(csv_link) %>% 
    dplyr::mutate_if(is.logical, as.numeric) %>% 
    data.table::data.table()
  csv <- original_csv
  
  fill_info_data <- function(design_table, csv, this_id, i){
    
    this_name <- 
      design_table %>% 
      .[mysteryBoxId == this_id] %>% 
      .[1, Name] %>% 
      stringr::str_remove_all(' Box')
    
    this_mb_name <- 
      this_name %>% 
      paste0('PrizeTent', ., 'Box')
    
    if(this_name == 'Voucher'){
      this_art_name <- 'collectibles'
    }else if(this_name == 'Tokens' | this_name == 'Token'){
      this_art_name <- 'token'
    }else if(this_name == 'Sticker'){
      this_art_name <- 'stickers'
    }else{
      this_art_name <- tolower(this_name)
    }
    
    this_icon_name <- paste0('UI/icons/GuildEvent/mysterybox_prizetent_', this_art_name)
    
    this_reset_count <- 
      design_table %>% 
      .[mysteryBoxId == this_id] %>% 
      .[1, `Reset Count`]
    
    csv[i, `#Mystery Box ID` := this_id]
    csv[i, `Mystery Box` := this_mb_name]
    csv[i, `icon prefab` := this_icon_name]
    csv[i, `3d asset prefab` := this_icon_name]
    csv[i, `Reset count` := this_reset_count]
    
    return(data.table::data.table(csv))
    
  }
  fill_prizes_data <- function(design_table, csv, this_id, i, j){
    prizes <- design_table %>% 
      .[mysteryBoxId == this_id] %>% 
      .[j, Prizes] %>% 
      stringr::str_split(' & ') %>% 
      unlist()
    
    
    # We need to differentiate between multiplie prizes with their multiple quantities or a single prize with multiple digit quantity
    # Example: 1 Ruby & 1 Diamond | 20 Gems.
    # So we create an array of the prizes and work individually on them.
    prizes_list <- prizes %>% stringr::str_split('&') %>% unlist()
    prizes_qty <- c()
    prizes_name <- c()
    
    for(pl in seq_along(prizes_list)){
      prizes_qty[[pl]] <- prizes_list[[pl]] %>% stringr::str_extract_all('[0-9]') %>% unlist() %>% paste(collapse = '') %>% as.numeric()
      prizes_name[[pl]] <- prizes_list[[pl]] %>% stringr::str_remove_all('[0-9]') %>% unlist() %>% stringr::str_trim()
    }
    
    weight <- 
      100*(design_table %>% 
             .[mysteryBoxId == this_id] %>% 
             .[j, Probability] %>% 
             stringr::str_remove('%') %>% 
             as.numeric()
      )
    
    csv[i , (paste0('Loot ', j, ' Weight')) := weight]
    
    for(k in seq_along(prizes)){
      
      if(prizes_name[[k]] %>% stringr::str_detect('Coin')){
        csv[i, (paste0('Loot ', j, ' Coins ', k)) := prizes_qty[[k]] %>% paste(collapse = '') %>%  as.numeric()]
      }else if(prizes_name[[k]] %>% stringr::str_detect('Gem')){
        csv[i, (paste0('Loot ', j, ' Gems ', k)) := prizes_qty[[k]]]
      }else if(prizes_name[[k]] %>% stringr::str_detect('Sticker')){
        qty <- prizes[[k]] %>% stringr::str_extract('.*Stickers') %>% stringr::str_extract_all('[0-9]') %>% unlist() %>% paste(collapse = '') %>% as.numeric()
        type <- prizes[[k]] %>% stringr::str_remove('.*Stickers') %>% stringr::str_extract_all('[0-9]') %>% unlist() %>% paste(collapse = '') %>% as.numeric()
        
        csv[i , (paste0('Loot ', j, ' Sticker count per type')) := qty[[k]]]
        csv[i , (paste0('Loot ', j, ' Sticker types')) := type[[k]]]
      }else{
        prize_id <- items_list[prizes_name[[k]] %>% stringr::str_detect(item_name)] %>% .$id
        csv[i , (paste0('Loot ', j, ' Item ', k)) := prize_id]
        csv[i , (paste0('Loot ', j, ' Quantity ', k)) := prizes_qty[[k]]]
      }
    }
    
    return(data.table::data.table(csv))
  }
  
  all_ids <- design_table$mysteryBoxId %>% unique() %>% sort()
  
  while(length(all_ids) > nrow(csv)) csv <- csv %>% add_row() %>% data.table()
  
  for(i in seq_along(all_ids)){
    this_id <- all_ids[[i]]
    csv <- fill_info_data(design_table, csv, this_id, i)
    
    n_prizes <- design_table %>% 
      .[mysteryBoxId == this_id] %>% 
      nrow()
    
    for(j in 1:n_prizes){
      csv <- fill_prizes_data(design_table, csv, this_id, i, j)
    }
  }
  data.table::fwrite(csv, csv_location)
  
  
  # prod ----------------------------------------------------------
  
  csv_location <- paste0('~/', game_folder, '/Assets/data/source/csv/prizetent_prod.csv')
  csv_link <- 'https://raw.githubusercontent.com/supersolid/spark/master/Assets/data/source/csv/prizetent_prod.csv?token=AEKOLXMZA3HL6IIQV2Z3YAS5P5XMG'
  
  original_csv <- data.table::fread(csv_location) %>% dplyr::mutate_if(is.logical, as.numeric) %>% data.table::data.table()
  csv <- original_csv
  
  all_ids <- design_table$mysteryBoxId %>% unique() %>% sort()
  while(length(all_ids) > nrow(csv)) csv <- csv %>% tibble::add_row() %>% data.table::data.table()
  
  fill_prod_info <- function(design_table, csv, this_id, i){
    this_shop_order <- design_table[`mysteryBoxId` == this_id, shopOrder] %>% .[[1]]
    this_mb_name <- design_table[`mysteryBoxId` == this_id, Name] %>% .[[1]] %>% stringr::str_remove_all(' ')
    this_lvl <- design_table[`mysteryBoxId` == this_id, Level] %>% .[[1]]
    this_colour <- design_table[`mysteryBoxId` == this_id, Colour] %>% .[[1]]
    
    
    # Fixing Inconsistent Names
    this_description_name <- this_mb_name
    if(this_mb_name %>% stringr::str_detect('Token'))   this_description_name <- 'TokenBox'
    if(this_mb_name %>% stringr::str_detect('Voucher')) this_description_name <- 'VoucherBox'
    if(this_mb_name %>% stringr::str_detect('Sticker')) this_description_name <- 'StickersBox'
    
    this_description_name <- this_description_name %>% paste0('Description')
    
    csv[i, `# mysteryBoxId` := this_id]
    csv[i, `shopOrder` := this_shop_order]
    csv[i, `descriptionKey` := this_description_name]
    csv[i, `playerLevel Requirement` := this_lvl]
    csv[i, `backgroundColor` := this_colour]
    
    # Cost
    this_cost <- design_table[mysteryBoxId == this_id] %>% .[1, Cost] %>% stringr::str_split(' & ') %>% unlist()
    for(k in seq_along(this_cost))
      cost_qty <-  this_cost %>% stringr::str_extract_all('[0-9]') %>% .[[k]] %>% as.numeric() %>% paste(collapse = '') %>% as.numeric()
    cost_name <- this_cost %>% stringr::str_remove_all('[0-9]')  %>% unlist() %>% stringr::str_trim() %>% .[[k]]
    
    if(cost_name %>% tolower() %>% stringr::str_detect('coin')){
      csv[i, `coins` := cost_qty ]
    } else if(cost_name %>% tolower() %>% stringr::str_detect('gem')){
      csv[i, `gems` := cost_qty ]
    }else{
      cost_id <- items_list[cost_name %>% stringr::str_detect(item_name), id]
      csv[i, (paste0('cost itemId #', k)) := cost_id]
      csv[i, (paste0('cost quantity #', k)) := cost_qty]
    }
    
    # Dates
    start_date <- design_table[mysteryBoxId == this_id] %>% .[1, `Start Date`]
    end_date <- design_table[mysteryBoxId == this_id] %>% .[1, `End Date`]
    
    if(start_date %>% tolower() %>% stringr::str_detect('perm')){
      csv[i, startDate := NA]
    }else{
      csv[i, startDate := paste0(start_date, 'T11:00:00Z')]
    }
    
    if(end_date %>% tolower() %>% stringr::str_detect('perm')){
      csv[i, endDate := NA]
    }else{
      csv[i, endDate := paste0(end_date, 'T11:00:00Z')]
    }
    
    return(data.table::data.table(csv))
  }
  
  for(i in seq_along(all_ids)){
    this_id <- all_ids[[i]]
    csv <- fill_prod_info(design_table, csv, this_id, i)
  }
  
  data.table::fwrite(csv, csv_location)
  
}




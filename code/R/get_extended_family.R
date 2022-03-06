get_extended_family <- function(pedigree, list_of_probands){
  # we identify probands who are related by identifying ancestors in common
  # first pull the list of probands
  gen0 <- pedigree %>% filter(ind %in% list_of_probands)
  # climb up the maternal side of the genealogy
  mothers <- pedigree %>% filter(ind %in% gen0$mother) %>%
    dplyr::rename(grand_mother=mother, grand_father=father, mother=ind)
  # climb up the fathers paternal side of the genealogy
  fathers <- pedigree %>% filter(ind %in% gen0$father) %>% 
    dplyr::rename(grand_father=father, grand_mother=mother, father=ind)
  
  # climb up the mothers maternal side of the genealogy
  mothersmother <- pedigree %>% filter(ind %in% mothers$grand_mother) %>% 
    dplyr::rename(great_grand_mother.mom=mother, great_grand_father.mom=father, grand_mother.mom=ind)
  # climb up the fathers maternal side of the genealogy
  fathersmother <- pedigree %>% filter(ind %in% fathers$grand_mother) %>% 
    dplyr::rename(great_grand_mother.dad=mother, great_grand_father.dad=father, grand_mother.dad=ind)
  
  # climb up the mothers paternal side of the genealogy
  mothersfather <- pedigree %>% filter(ind %in% mothers$grand_father) %>% 
    dplyr::rename(great_grand_mother.mom=mother, great_grand_father.mom=father, grand_father.mom=ind)
  # climb up the fathers paternal side of the genealogy
  fathersfather <- pedigree %>% filter(ind %in% fathers$grand_father) %>% 
    dplyr::rename(great_grand_mother.dad=mother, great_grand_father.dad=father, grand_father.dad=ind)
  
  extended_families <- 
    gen0 %>% 
    left_join(mothers, by = "mother") %>% 
    left_join(fathers, by = "father", suffix=c(".mom",".dad")) %>% 
    left_join(mothersmother, by = "grand_mother.mom") %>% 
    left_join(mothersfather, by = "grand_father.mom") %>% 
    left_join(fathersmother, by = "grand_mother.dad") %>% 
    left_join(fathersfather, by = "grand_father.dad")
  
  return(extended_families)
}
# Get the deepest generation for each internal node
maximum_genealogical_depth <- function(pedigree, list_of_probands) {
  # probands are individuals at generation 0
  individuals <- data.frame(ind = list_of_probands, generation = 0)
  # initialize output to append to downstream
  gen_depth <- individuals
  # for loop to iterate through generations
  for (k in 1:18) {
    individuals_parents <-
      # start from the entire pedigree
      pedigree %>%
      # keep parents of individuals at generation 'k'
      filter(ind %in% individuals$ind) %>%
      # if parent is missing, flag individual as founder
      mutate(founder = case_when(
        is.na(father) | is.na(mother) ~ T,
        father == 0 | mother == 0 ~ T,
        TRUE ~ F
      ))

    # stop climbing when there are only founders left
    if (nrow(filter(individuals_parents, founder == F)) == 0) {
      break
    }

    # to ascend genealogy, parents become reference individuals
    mothers <- unique(individuals_parents$mother)
    fathers <- unique(individuals_parents$father)
    # recursion step reassigns reference individuals
    individuals <-
      data.frame(ind = c(mothers, fathers), generation = k) %>%
      filter(!is.na(ind)) # removes missing IDs

    # output max depth per individual
    gen_depth <-
      # individuals already visited by climbing algorithm
      gen_depth %>%
      # remove duplicate individuals at 'k-1'
      filter(!ind %in% individuals$ind) %>%
      # append updated individuals 'k' generations deep
      bind_rows(individuals)
  }
  # do not include founder-0 as individual
  out <- gen_depth %>%
    filter(ind != 0) %>%
    left_join(pedigree, by = "ind")
  
  return(out)
}

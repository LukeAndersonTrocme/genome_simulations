import os
import pandas as pd
import numpy as np
import msprime

def load_and_verify_pedigree(fname):
    """
    Output: verified four column pedigree dataframe

    Input:
    fname: string giving location of txt_ped-formatted genealogy.
    columns represent:  ind, mother, father, generation

    This function:
    checks if file exists,
    sorts table in decending genealogical order (oldest to newest)
    identify pedigree founders and assing -1 values
    """
    # ensure file exists
    try:
        f = open(fname, 'rb')
    except FileNotFoundError:
        print("file {} does not exist".format(fname))
        raise

    # genealogy_table instead of fp

    #  load the genealogy file
    fp = pd.read_csv(fname)
    # reverse sort by pseudo-time such that parents are before their children
    fp = fp.sort_values(["generation"], ascending = (False)).reset_index(drop=True)

    # identify and recode founder individuals

    # these are the individuals in the pedigree
    ped_inds = fp["ind"].values
    # assign -1 to founding fathers
    fp.loc[~fp["father"].isin(ped_inds), "father"] = -1
    # assign -1 to founding mothers
    fp.loc[~fp["mother"].isin(ped_inds), "mother"] = -1

    return fp

def add_individuals_to_pedigree(pb, text_pedigree, f_pop, p_pop):
    """
    Output: PedigreeBuilder object built from text_pedigree

    Input:
    pb: an msprime builder pedigree with a predefined demography
    text_pedigree: four column text pedigree from load_and_verify_genealogy

    This function:
    loops through each individual in text pedigree
    adds individual to msprime pedigree with:
    parents, time, population and metadata of individual_name from text pedigree
    """
    # dictionaries linking text_pedigree ids to msprime ids
    txt_ped_to_tskit_key = {}
    #tskit_to_txt_ped_key = {}

    # for each individual in the genealogy
    for i in text_pedigree.index:
        # relevant information to load into PedigreeBuilder
        ind_time = text_pedigree["generation"][i]
        ind_id = text_pedigree["ind"][i]
        father_id = text_pedigree["father"][i]
        mother_id = text_pedigree["mother"][i]

        # add father
        if father_id == -1 :
            father = pb.add_individual(time=ind_time+1,
                                       population=f_pop,
                                       metadata={"individual_name": str(father_id)})
        else:
            try:
                father = txt_ped_to_tskit_key[father_id]
            except KeyError:
                print("father key missing, check order of dictionary construction")
                raise

        # add mother
        if mother_id == -1 :
            mother = pb.add_individual(time=ind_time+1,
                                       population=f_pop,
                                       metadata={"individual_name": str(mother_id)})

        else:
            try:
                mother = txt_ped_to_tskit_key[mother_id]
            except KeyError:
                print("mother key missing, check order of dictionary construction")
                raise

        # add individual
        child = pb.add_individual(time=ind_time,
                                  parents=[mother,father],
                                  population=p_pop,
                                  metadata={"individual_name": str(ind_id)})
        # update dictionary for downstream
        txt_ped_to_tskit_key[ind_id] = child # store for later use (?)
        # tskit_to_txt_ped_key[child] = ind_id

    return pb

def simulate_genomes_with_known_pedigree(
                                         text_pedigree,
                                         demography,
                                         model = "hudson",        # model to recapitulate tree
                                         f_pop = "CEU",           # population id of founders
                                         p_pop = 0,               # population id in pedigree
                                         mutation_rate = 2.36e-8, # from Gutenkunst 2009
                                         rate_map = 1.20e-8,
                                         sequence_length = 1,
                                         seed = 123
                                         ):
    """
    Output: simulated genomes using input text pedigree

    Input:
    text_pedigree: four column text pedigree from load_and_verify_genealogy
    demography: msprime demography specification
    model: used to recapitulate the fixed pedigree -- "hudson" or "WF"
    f_pop: population id of founders
    p_pop: population id in pedigree
    sequence_length: genome length of tree sequence
    rate_map: recombination rate map defined by load_rate_map
    mtuation_rate: mutation rate used for dropping mutations down tree sequence
    seed: random seed used in simulations

    This function:
    initializes an msprime PedigreeBuilder from demography
    builds a pedigree using the input text_pedigree
    runs msprime.sim_ancestry within fixed pedigree (default diploid)
    using the recombination rate provided
    drops mutations down tree using provided mutation rate
    """
    # demography used to recapitulate beyond input pedigree
    pb = msprime.PedigreeBuilder(demography)

    # build pedigree using input pedigree
    pb = add_individuals_to_pedigree(pb, text_pedigree, f_pop, p_pop)

    # check simple model https://github.com/tskit-dev/msprime/blob/57ef4ee3267cd9b8e711787539007b0cde94c55c/tests/test_pedigree.py#L151

    # initial state of tree sequence
    ts = pb.finalise(sequence_length = sequence_length)

    # simulation within fixed pedigree
    ts = msprime.sim_ancestry(
        initial_state = ts,
        recombination_rate = rate_map,
        model = "fixed_pedigree",
        random_seed = seed + 100
        )

    # simulation beyond fixed pedigree
    ts = msprime.sim_ancestry(
        initial_state = ts,
        recombination_rate = rate_map,
        demography = demography,
        random_seed = seed + 200,
        model = model # Could also do WF
        )
    # drop mutations down the tree
    ts = msprime.sim_mutations(
              ts,
              rate = mutation_rate,
              random_seed = seed + 300
              )

    return ts

def simulation_sanity_checks(ts, ped):
    """
    ts is the output of run_fixed_pedigree_simulation
    text_pedigree is the output of load_and_verify_genealogy
    """

    # probands are by definition at generation 0
    probands = ped.loc[ped['generation'] == 0]["ind"].values

    # reacall diploids have two nodes per sample
    assert ts.num_samples == 2 * len(probands)

    # TODO : assert samples IDs are the correctly stored
    #ts.tables.individuals[5].metadata['individual_name']

    pass
import os
import pandas as pd
import numpy as np
import msprime

def load_and_verify_pedigree(fname):
    """
    Output: verified four column pedigree dataframe

    Input:
    fname: string giving location of txt_ped-formatted genealogy.
    columns represent:  ind, mother, father, generation (lon, lat are optional)

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

    # determine if lon lat present in text pedigree
    if {'lon', 'lat'}.issubset(text_pedigree.columns):
        geo = True
    else :
        geo = False

    # determine if marriage loc present in text pedigree
    if {'lieum'}.issubset(text_pedigree.columns):
        loc = True
    else :
        loc = False

    # determine if marriage decade present in text pedigree
    if {'decade'}.issubset(text_pedigree.columns):
        decade = True
    else :
        decade = False

    # determine if new id is present in text pedigree
    if {'sex'}.issubset(text_pedigree.columns):
        sex = True
    else :
        sex = False

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

        if geo and loc and decade and sex :
            metadata={"individual_name": str(ind_id),
                      "geo_coord":[text_pedigree["lat"][i],text_pedigree["lon"][i]],
                      "loc":str(text_pedigree["lieum"][i]),
                      "decade":str(text_pedigree["decade"][i]),
                      "sex":str(text_pedigree["sex"][i]),
                      }
        elif geo and loc and sex :
            metadata={"individual_name": str(ind_id),
                      "geo_coord":[text_pedigree["lat"][i],text_pedigree["lon"][i]],
                      "loc":str(text_pedigree["lieum"][i]),
                      "sex":str(text_pedigree["sex"][i]),
                      }
        elif geo and decade and sex :
            metadata={"individual_name": str(ind_id),
                      "geo_coord":[text_pedigree["lat"][i],text_pedigree["lon"][i]],
                      "decade":str(text_pedigree["decade"][i]),
                      "sex":str(text_pedigree["sex"][i]),
                      }
        elif sex :
            metadata={"individual_name": str(ind_id),
                      "sex":str(text_pedigree["sex"][i]),
                      }
        else :
            metadata={"individual_name": str(ind_id)}
        # add individual
        child = pb.add_individual(time=ind_time,
                                  parents=[mother,father],
                                  population=p_pop,
                                  metadata=metadata)

        # update dictionary for downstream
        txt_ped_to_tskit_key[ind_id] = child # store for later use (?)

    return pb

#def del_individual_name(md):
#    del md["individual_name"]
#    return md

def del_sensitive_metadata(md):
    del md["date"]
    del md["new_id"]

    return md

def censor_pedigree(ts):
    """
    Output: a censored tree sequence (i.e. without parent-child links or IDs)

    Input:
    ts: a tree sequence

    This function:
    removes all sensitive metadata from the input text pedigree
    specifically, it removes:
    - individual_names
    - parents of each individual
    """

    tables = ts.dump_tables()

    new_metadata = [del_sensitive_metadata(i.metadata) for i in tables.individuals]

    validated_metadata = [
        tables.individuals.metadata_schema.validate_and_encode_row(row) for row in new_metadata
    ]
    tables.individuals.packset_metadata(validated_metadata)

    # remove parents
    tables.individuals.packset_parents([[]] * tables.individuals.num_rows)

    censored_ts = tables.tree_sequence()

    return(censored_ts)

def clean_pedigree_for_publication(ts):
    """
    Output: a cleaned tree sequence file (i.e. clean metadata, provenances, etc.)

    Input:
    ts: a tree sequence

    This function:
    removes useless metadata and provenances from the input tree sequence
    specifically:
    - sets geographical coordinates to `location`
    - only keeps the first two provenance entries
    - only keeps metadata cleared for publication
    """
    # ensure pedigree is censored
    ts = censor_pedigree(ts)

    # load tables
    tables = ts.dump_tables()
    # only keep first two entries of provenances
    tables.provenances.truncate(2)
    # get the lat and lon for each individual
    location = np.array(list(ind.metadata["geo_coord"] for ind in ts.individuals()))

    n = ts.num_individuals

    # set the location to lat/lon
    tables.individuals.set_columns(
            flags=tables.individuals.flags,
            location=location.reshape(2 * n),
            location_offset=2 * np.arange(n + 1, dtype=np.uint64),
            metadata=tables.individuals.metadata,
            metadata_offset=tables.individuals.metadata_offset)

    clean_ts = tables.tree_sequence()
    return(clean_ts)

def simulate_genomes_with_known_pedigree(
                                         text_pedigree,
                                         demography,
                                         model = "hudson",        # model to recapitulate tree
                                         f_pop = "EUR",           # population id of founders
                                         p_pop = "EUR",           # population id in pedigree
                                         mutation_rate = 3.62e-8,
                                         rate_map = 1.20e-8,
                                         sequence_length = 1,
                                         sequence_length_from_assembly = 1,
                                         centromere_intervals = [0,0],
                                         censor = True,
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
    sequence_length_from_assembly: length including telomeres
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

    if(censor): ts = censor_pedigree(ts)

    # remove centromere
    ts = ts.delete_intervals(intervals = centromere_intervals)
    # modify sequence length to include `right` telomere
    tables = ts.dump_tables()
    tables.sequence_length = sequence_length_from_assembly
    ts = tables.tree_sequence()
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


def drop_mutations_again(
                         ts,
                         inside_mut = 2.36e-8,
                         outside_mut = 3.62e-8,
                         seed = 0,
                         ):
    """
    Output: tree sequence with a new set of mutations

    Input:
    ts: a tree sequence
    inside_mut: mutation rate used _inside_ fixed pedigree
    outside_mut: mutation rate use _outside_ fixed pedigree

    NOTE: outisde_mut should match the one used in the demographic model.

    This function:
    removes all sites and mutations from the input tree sequence
    drops mutations down tree using provided the two mutation rates
    the optional seed argument can be used to generate new simulations
    """

    # load tables
    tables = ts.dump_tables()
    # remove sites
    tables.sites.clear()
    # remove mutations
    tables.mutations.clear()
    # turn this back into a tree sequence
    ts_nomuts = tables.tree_sequence()

    # cut tree seuquence into two based on start_time and end_time
    # ts_nomuts_inside =
    # ts_nomuts_outside =

    # drop mutations down the tree
    ts_inside = msprime.sim_mutations(
              ts_nomuts_inside,
              rate = inside_mut,
              random_seed = seed
              )

    # drop mutations down the tree
    ts_outside = msprime.sim_mutations(
              ts_nomuts_outside,
              rate = outside_mut,
              random_seed = seed
              )

    # ts_out = ts_inside + ts_outside

    #return(ts)
    pass

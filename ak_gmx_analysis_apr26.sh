#!/bin/bash
#
echo "Excellent site for data analysis in gromacs"
echo "http://md.chem.rug.nl/~mdcourse/molmod2012/analysis.html"
echo "you are in $(pwd)"
in_pdb=${1?Error: please give pdb file name}
echo "given file name is $in_pdb"

#### strip .pdb from name###
mod_pdb=${in_pdb%.pdb}

##############################################
#
####check mdrun folder for the given pdb exist in directory###
#
##############################################

if [ -d "$mod_pdb" ]
then 
     echo "$mod_pdb folder exists in $(pwd)"
else
     echo "$in_pdb folder does not exist, check whether MD run for pdb is performed or not "
     exit 1
fi

analysis=$(pwd)/$mod_pdb/md_analysis
run=$(pwd)/$mod_pdb/md_run

cd $run


#############################################
#
###Analysis MD##
#
#############################################

###Output plot of C alpha RMSF relative to the structure present in the minimized, equilibrated system

trjconv_analysis() {
#echo 1 | gmx trjconv -s md_01_$mod_pdb.tpr -f md_01_$mod_pdb.xtc -o md_01_noPBC_$mod_pdb.xtc -pbc mol -ur compact -dt 500

#### Following works in case of dimer while above one may be good for monomer type of protein md simulation
#read -p "Check -s (.gro/.tpr) option of trjconv command in VMD, if starting/reference molecule is not WHOLE in unit cell than -pbc nojump will not work, in that case choose gro file from em/nvt/npt step for input, Press [Enter] key for continue or [ctr+c] to exit"
echo 1 | gmx trjconv -s em_$mod_pdb.tpr -f md_01_$mod_pdb.xtc -o md_01_noPBC_$mod_pdb.xtc -pbc nojump -dt 500
}

structural_analysis() {
###Output plot will show the RMSD relative to the structure present in the minimized, equilibrated system
echo 2 2 | gmx rms -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_$mod_pdb.xvg &

### Output plot of RMSD relative to the crystal structure ######
echo 2 2 | gmx rms -s em_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_xtal_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_xtal_$mod_pdb.xvg &

###Output plot of RMSF relative to the structure present in the minimized, equilibrated system
echo 2 | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsf_$mod_pdb.xvg -ox $analysis/rmsf_avg_$mod_pdb.pdb -res
xmgrace $analysis/rmsf_$mod_pdb.xvg &

###Output plot of C alpha RMSF relative to the structure present in the minimized, equilibrated system
echo 3 | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsf_Ca_$mod_pdb.xvg -res
xmgrace $analysis/rmsf_Ca_$mod_pdb.xvg &

##Following command is used to generate Bfactor file with starting structure will be taken##
##from -s em_xxx.tpr file. Because md_01_xxx.tpr somehow spit fragmeted b factor pdb###
echo 2 | gmx rmsf -s em_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -oq $analysis/rmsf_bfac_$mod_pdb.pdb -res

### Output plot to compare RMSD with average structure for all atom as well as for backbone only ####
### Note it require pdb file with average coordinates saved, so gmx rmsf command is neccessary to generate pdb #####
echo 4 4 | gmx rms -s $analysis/rmsf_avg_$mod_pdb.pdb -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_bb-vs-avg_$mod_pdb.xvg -tu ns
echo 2 2 | gmx rms -s $analysis/rmsf_avg_$mod_pdb.pdb -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_allatom-vs-avg_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_bb-vs-avg_$mod_pdb.xvg &
xmgrace $analysis/rmsd_allatom-vs-avg_$mod_pdb.xvg &

### Output plot the radius of gyration of simulated structure ######
echo 2 | gmx gyrate -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/gyrate_$mod_pdb.xvg
xmgrace $analysis/gyrate_$mod_pdb.xvg &

### Output pdb file with thermal noise i.e high frequency motion filtered ######
### Not much useful as same can be done in pymol by 'smooth' command #####

#gmx filter  -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -ol $analysis/filtered_50_$mod_pdb.pdb -nf 5 -dt 50


### check the minimum distance between periodic images to ensure no direct interactions#####
### between periodic molecule in adjacent boxes, good for quality assurance ##########
###Ideally, the minimal distance should therefore not be less than two nanometer.###
echo 2 | gmx mindist -f md_01_noPBC_$mod_pdb.xtc -s md_01_$mod_pdb.tpr -od $analysis/minimal-periodic-distance_$mod_pdb.xvg -pi
xmgrace $analysis/minimal-periodic-distance_$mod_pdb.xvg &
echo " check the graph distance on average should be more than 2 nm"

# still not working incase of writing b-factors using gmx rmsf command with-q *.pdb option
## Extract a pdb file from the md run trajectory that is pbc corrected#####
#echo 2 | gmx trjconv -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -dump 0 -o $analysis/md_01_first-frame_$mod_pdb.pdb
}

############Creation chain indices for Rg and RMSF analysis ##################
create_chain_indices() {
    echo "Generating index files for chain-wise analysis..."

    ndx_ca=index_${mod_pdb}_ca.ndx
    ndx_prot=index_${mod_pdb}_prot.ndx

    # C-alpha based splitting (for RMSF)
    if [[ ! -f "$ndx_ca" ]]; then
        printf "splitch %s\nq\n" "3" | gmx make_ndx -f md_01_${mod_pdb}.gro -o $ndx_ca > ndx_ca.log 2>&1
    fi

    # Protein-H based splitting (for Rg)
    if [[ ! -f "$ndx_prot" ]]; then
        printf "splitch %s\nq\n" "2" | gmx make_ndx -f md_01_${mod_pdb}.gro -o $ndx_prot > ndx_prot.log 2>&1
    fi

    # Extract chain count (same for both)
    num_chains=$(grep -oP 'Found \K[0-9]+' ndx_prot.log)

    if [[ -z "$num_chains" ]]; then
        echo "Error: Could not detect chains."
        exit 1
    fi

    echo "$num_chains" > chain_count.log
    echo "Detected $num_chains chains."
}

get_chain_indices() {
    ndx_file=$1

    num_chains=$(cat chain_count.log)
    total_groups=$(grep -c "\[" $ndx_file)
    start_index=$((total_groups - num_chains))

    echo "$start_index $num_chains"
}


############gmx sasa ananlysis##################
sasa_analysis() {
echo 1 | gmx sasa -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/sasa_$mod_pdb.xvg -or $analysis/sasa_res_$mod_pdb.xvg -tu ns
xmgrace $analysis/sasa_$mod_pdb.xvg &
xmgrace $analysis/sasa_res_$mod_pdb.xvg &
}

### Hydrogen bonding analysis ###
hbond_analysis() {
    echo "Starting hydrogen bond analysis..."

    # Intra-protein H-bonds number and avg distance
    echo 1 1 | gmx hbond -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc \
        -num $analysis/hbond_protein_num_$mod_pdb.xvg \
        -dist $analysis/hbond_protein_dist_$mod_pdb.xvg 
    # Plot
    xmgrace $analysis/hbond_protein_num_$mod_pdb.xvg &
    xmgrace $analysis/hbond_protein_dist_$mod_pdb.xvg &
   
    echo "Hydrogen bond analysis completed."
}

### Output pdb file for visulation of simulated structure with some time step in ps by -dt ######
pymol_traj_extract() {
    echo 2 | gmx trjconv  -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/traj_200psStep_$mod_pdb.pdb -dt 2000

    echo "spectrum
    show cell
    intra_fit traj_200psStep_$mod_pdb
    orient
    show cartoon
    dss
    smooth" > $analysis/pymol_command_$mod_pdb.pml
}

gyration_chainwise_analysis() {
    echo "Starting chain-wise Rg analysis (Protein level)..."

    ndx_file=index_${mod_pdb}_prot.ndx

    read start_index num_chains <<< $(get_chain_indices $ndx_file)
    echo "start_index: $start_index , num_chains: $num_chains"
    for i in $(seq 0 $((num_chains-1))); do
        chain_index=$((start_index + i))
        chain_id=$((i+1))

        echo "$chain_index" | gmx gyrate \
            -s md_01_${mod_pdb}.tpr \
            -f md_01_noPBC_${mod_pdb}.xtc \
            -n $ndx_file \
            -o ${analysis}/gyrate_chain${chain_id}_${mod_pdb}.xvg

        xmgrace ${analysis}/gyrate_chain${chain_id}_${mod_pdb}.xvg &
    done

    echo "Chain-wise Rg completed."
}

rmsf_chainwise_analysis() {
    echo "Starting chain-wise RMSF analysis (Cα level)..."

    ndx_file=index_${mod_pdb}_ca.ndx

    read start_index num_chains <<< $(get_chain_indices $ndx_file)
    echo "start_index: $start_index , num_chains: $num_chains"
    for i in $(seq 0 $((num_chains-1))); do
        chain_index=$((start_index + i))
        chain_id=$((i+1))

        echo "$chain_index" | gmx rmsf \
            -s md_01_${mod_pdb}.tpr \
            -f md_01_noPBC_${mod_pdb}.xtc \
            -n $ndx_file \
            -o ${analysis}/rmsf_Ca_chain${chain_id}_${mod_pdb}.xvg \
            -res

        xmgrace ${analysis}/rmsf_Ca_chain${chain_id}_${mod_pdb}.xvg &
    done

    echo "Chain-wise RMSF completed."
}

#-----------------------------------------------------------------------------------------
# Call the analysis function at the end of all analysis routine:

#trjconv_analysis
create_chain_indices

#structural_analysis
#sasa_analysis
#hbond_analysis

gyration_chainwise_analysis
#rmsf_chainwise_analysis

#------------------------------------------------------------------------------------------


exit

##### code to make index file and extracting chainwise rmsf using index file
#gmx make_ndx -f md_01_$mod_pdb -o index_$mod_pdb.ndx

#gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsf_ChainD_$mod_pdb.xvg -n index_$mod_pdb.ndx -res
#xmgrace $analysis/rmsf_ChainD_$mod_pdb.xvg &

#exit

#############################################
#
### RMSF for Individual Chains more autoamated code ###
#
#############################################
# Define variables
start_index=17      # Starting index of chains
index_choice=3      # User-defined index (e.g., 3 for Cα)
num_chains=0        # Initialize chain count

# Generate index file (Splitting chains at Cα level)
printf "splitch %s\nq\n" "$index_choice" | gmx make_ndx -f md_01_$mod_pdb.gro -o index_$mod_pdb.ndx | tee ndx_output.log 

# Extract the number of chains from gmx make_ndx output
num_chains=$(grep -oP 'Found \K[0-9]+' ndx_output.log)

# Ensure num_chains is not empty
if [[ -z "$num_chains" ]]; then
    echo "Error: Could not determine the number of chains."
    exit 1
fi

echo "Detected $num_chains chains, starting from index $start_index."

# Loop through each chain and compute RMSF
for i in $(seq 0 $((num_chains-1))); do
    chain_index=$((start_index + i))
    echo "Processing Cα RMSF for Chain $((i+1)) (Index: $chain_index)..."

    # Compute RMSF
    echo "$chain_index" | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc \
        -o ${analysis}/rmsf_Ca_Chain$((i+1))_$mod_pdb.xvg -n index_$mod_pdb.ndx -res

    # Visualize RMSF results
    xmgrace ${analysis}/rmsf_Ca_Chain$((i+1))_$mod_pdb.xvg &

    echo "RMSF analysis for Chain $((i+1)) completed."
done

echo "All chains processed successfully!"
exit

#############################################
#
### PCA Analysis MD##
#
#############################################

mkdir $analysis/pca_$mod_pdb
pca_dir=$analysis/pca_$mod_pdb
echo "PCA analysis will be done and results will be written in $pca_dir"

#The covariance matrix of the atomic fluctuations will be build. Diagonalisation of this matrix yields a set of eigenvectors and eigenvalues, that describe collective modes of fluctuations of the protein. The eigenvectors corresponding to the largest eigenvalues are called "principal components", as they represent the largest-amplitude collective motions.

echo 4 4 | gmx covar  -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $pca_dir/md_01_eigenvalues_$mod_pdb.xvg -v $pca_dir/md_01_eigenvectors_$mod_pdb.trr -last 9
xmgrace $pca_dir/md_01_eigenvalues_$mod_pdb.xvg &

#Only a very small number of eigenvectors (modes of fluctuation) contribute significantly to the overall motion of the protein. 
#To view dominant mode we will use following command in gromacs also motion is jerky which will be smoothen by artificially interpolating between extreme confirmation

echo 4 4 | gmx anaeig -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -v $pca_dir/md_01_eigenvectors_$mod_pdb.trr -first 1 -last 1 -nframes 100 -extr $pca_dir/md_01_eigenV1_$mod_pdb.pdb

#For a more quantitatve analysis, we can project the trajectory onto individual eigenvectors, and display the projections as a function of time:

echo 4 4 | gmx anaeig -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -v $pca_dir/md_01_eigenvectors_$mod_pdb.trr -first 1 -last 9 -proj $pca_dir/md_01_proj_1-9_$mod_pdb.xvg -tu ns
xmgrace $pca_dir/md_01_proj_1-9_$mod_pdb.xvg &



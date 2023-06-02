#bin/bash
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

#echo 1 | gmx trjconv -s md_01_$mod_pdb.tpr -f md_01_$mod_pdb.xtc -o md_01_noPBC_$mod_pdb.xtc -pbc mol -ur compact -dt 500

#### Following works in case of dimer while above one may be good for monomer type of protein md simulation
#read -p "Check -s (.gro/.tpr) option of trjconv command in VMD, if starting/reference molecule is not WHOLE in unit cell than -pbc nojump will not work, in that case choose gro file from em/nvt/npt step for input, Press [Enter] key for continue or [ctr+c] to exit"
echo 1 | gmx trjconv -s em_$mod_pdb.tpr -f md_01_$mod_pdb.xtc -o md_01_noPBC_$mod_pdb.xtc -pbc nojump -dt 500

###Output plot will show the RMSD relative to the structure present in the minimized, equilibrated system
echo 2 2 | gmx rms -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_$mod_pdb.xvg &

### Output plot of RMSD relative to the crystal structure ######
echo 2 2 | gmx rms -s em_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_xtal_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_xtal_$mod_pdb.xvg &


###Output plot of RMSF relative to the structure present in the minimized, equilibrated system
echo 2 | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsf_$mod_pdb.xvg -ox $analysis/rmsf_avg_$mod_pdb.pdb -res
xmgrace $analysis/rmsf_$mod_pdb.xvg &

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


### Output pdb file for visulation of simulated structure with some time step in ps by -dt ######
echo 2 | gmx trjconv  -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/traj_200psStep_$mod_pdb.pdb -dt 2000

echo "spectrum
show cell
intra_fit traj_200psStep_$mod_pdb
orient
show cartoon
dss
smooth" > pymol_command_$mod_pdb.pml

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



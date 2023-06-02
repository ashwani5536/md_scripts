#bin/bash
#
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

##############################################
#
###Production MD##
#
#############################################

gmx grompp -f md.mdp -c npt_$mod_pdb.gro -r npt_$mod_pdb.gro -t npt_$mod_pdb.cpt -p topol.top -o md_01_$mod_pdb.tpr
gmx mdrun -v -deffnm md_01_$mod_pdb

#### Used following format of commands to run two parallel jobs in two cores###
#gmx mdrun -v -deffnm md_01_$mod_pdb -gpu_id 1 -ntmpi 1 -ntomp 12 -pin on -pinoffset 16 -pinstride 1
#gmx mdrun -v -deffnm md_01_$mod_pdb -gpu_id 0 -ntmpi 1 -ntomp 12 -pin on -pinoffset 0 -pinstride 1

## To extend the previous md run #########
# gmx mdrun -v -deffnm md_01_$mod_pdb -cpi md_01_$mod_pdb.cpt -maxh 63.0

## To extend on one gpu with pinning the core 
#gmx mdrun -v -deffnm md_01_$mod_pdb -cpi md_01_$mod_pdb.cpt -gpu_id 0 -ntmpi 1 -ntomp 12 -pin on -pinoffset 0 -pinstride 1 -nsteps -1 -maxh 24.0




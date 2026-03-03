#!/bin/bash
set -e

echo "you are in $(pwd)"
in_pdb=${1?Error: please give pdb file name}
mod_pdb=${in_pdb%.pdb}

GMX_GPU="-gpu_id 0 -ntmpi 1 -ntomp 10"
FF="amber99sb-ildn" #amber14sb, amber19sb, charmm27, amber14sb_OL24, charmm36-jul2022,charmm36_ljpme-jul2022 
H2O="tip3p" #opc, opc3, spc, spce, tip3p, tip4p, tip4pew, tip5p, tips3p
BOX="dodecahedron" # cubic

##############################################
# Check mdp files
##############################################
list="ions.mdp minim.mdp nvt.mdp npt.mdp md.mdp"

for var in $list; do
    [ -f "$var" ] || { echo "Missing $var"; exit 1; }
done
echo "Following mdp files are available in directory:  "$(ls *.mdp)

check_create_folder() {
##############################################
# Create folder structure
#check mdrun folder for the given pdb exist in directory
##creating new directory with pdb name and processing everything there related to particular pdb###
# also creating mdrun and analysis directory with in pdb directory to separately storing mdrun and analysis files
##############################################
echo "Cheking the presence of $mod_pdb folder in directory"
analysis=$(pwd)/$mod_pdb/md_analysis
run=$(pwd)/$mod_pdb/md_run

if [ -d "$mod_pdb" ]
then 
     echo "$mod_pdb folder exists in $(pwd), Check the folder for MD run"
     exit 1     
else
     echo "$in_pdb folder does not exist"
     echo "A new directory structure will be created to run and analyse MD of $in_pdb"
     mkdir $(pwd)/$mod_pdb
     mkdir $run
     mkdir $analysis
     cp $in_pdb $mod_pdb/md_run
     cp *.mdp $mod_pdb/md_run
     echo "new directory by name $mod_pdb, md_run and md_analysis is created "
fi

cd $run
}

check_only_folder() {
echo "Cheking the presence of $mod_pdb folder in directory"
analysis=$(pwd)/$mod_pdb/md_analysis
run=$(pwd)/$mod_pdb/md_run
if [ -d "$mod_pdb" ]
then 
     echo "$mod_pdb folder exists in $(pwd)"
     if [ -d "$run" ]
     then
          echo "$run folder exit, will continue the md run from last"
          cd $run
     else
          echo "$run folder does not exists in $(pwd), exiting MD run"
          exit 1 
     fi
else
     echo "$mod_pdb folder does not exists in $(pwd), exiting MD run"
     exit 2 
fi
}


pre_processing() {
##############################################
#
###check the file for missing residues###
#
##############################################

echo "checking the file for missing residues"
if grep -q 'REMARK 465 MISSING RESIDUES' $in_pdb; then
    echo "$in_pdb has missing atom, check the file manually!!!"
    exit 1
else
     echo " file do not have missing residues"
fi

##############################################
# Remove crystallographic water
##############################################
grep -v HOH $in_pdb > ${mod_pdb}_clean.pdb

##############################################
# Topology
##############################################
gmx pdb2gmx -f ${mod_pdb}_clean.pdb -o ${mod_pdb}_processed.gro -ff $FF -water $H2O

##############################################
# Box + solvate
##############################################
gmx editconf -f ${mod_pdb}_processed.gro -o ${mod_pdb}_newbox.gro -c -d 1.0 -bt $BOX
gmx solvate -cp ${mod_pdb}_newbox.gro -cs spc216.gro -o ${mod_pdb}_solv.gro -p topol.top

##############################################
# Ions
##############################################
gmx grompp -f ions.mdp -c ${mod_pdb}_solv.gro -p topol.top -o ions.tpr -maxwarn 2
echo "SOL" | gmx genion -s ions.tpr -o ${mod_pdb}_solv_ions.gro -p topol.top -pname NA -nname CL -neutral

##############################################
# Energy minimization
##############################################
gmx grompp -f minim.mdp -c ${mod_pdb}_solv_ions.gro -p topol.top -o em_$mod_pdb.tpr
gmx mdrun -v -deffnm em_$mod_pdb

echo "check that Epot should be negative of order of 10**5-10**6,"

echo "Potential" | gmx energy -f em_$mod_pdb.edr -o $analysis/potential_$mod_pdb.xvg
xmgrace $analysis/potential_$mod_pdb.xvg &
}

nvt_equib() {
##############################################
# NVT: stabilized the temperature of the system
##############################################
gmx grompp -f nvt.mdp -c em_$mod_pdb.gro -r em_$mod_pdb.gro -p topol.top -o nvt_$mod_pdb.tpr
gmx mdrun -v -deffnm nvt_$mod_pdb $GMX_GPU

echo "Temperature" | gmx energy -f nvt_$mod_pdb.edr -o $analysis/temperature_$mod_pdb.xvg
xmgrace $analysis/temperature_$mod_pdb.xvg &
}

npt_equib() {
##############################################
# NPT (Berendsen – density equilibration)
##############################################
gmx grompp -f npt.mdp -c nvt_$mod_pdb.gro -r nvt_$mod_pdb.gro -t nvt_$mod_pdb.cpt -p topol.top -o npt_$mod_pdb.tpr
gmx mdrun -v -deffnm npt_$mod_pdb $GMX_GPU

echo "Density" | gmx energy -f npt_$mod_pdb.edr -o $analysis/density_$mod_pdb.xvg
echo "Pressure" | gmx energy -f npt_$mod_pdb.edr -o $analysis/pressure_$mod_pdb.xvg
}

md_run_start() {
##############################################
# Production MD
##############################################
gmx grompp -f md.mdp -c npt_$mod_pdb.gro -t npt_$mod_pdb.cpt -p topol.top -o md_01_$mod_pdb.tpr
gmx mdrun -v -deffnm md_01_$mod_pdb $GMX_GPU -cpi md_01_$mod_pdb.cpt
}

md_run_continue() {
##############################################
# Production MD continue
##############################################
gmx mdrun -v -deffnm md_01_$mod_pdb $GMX_GPU -cpi md_01_$mod_pdb.cpt
}




# Prompt user for action
echo "Choose an action:"
echo "1. First md run"
echo "2. Continue extisting before md run"
echo "3. Continue existing md run"
read -p "Enter the number corresponding to your choice: " choice

# Perform the chosen action
case $choice in
    1)
        check_create_folder
        pre_processing
	nvt_equib
	npt_equib
	md_run_start
        ;;
    2)
        check_only_folder
        #pre_processing
	#nvt_equib
	#npt_equib
	#md_run_start
	;;
    3)
        check_only_folder
        md_run_continue
        ;;    
    *)
        echo "Invalid choice. Exiting."
        ;;
esac

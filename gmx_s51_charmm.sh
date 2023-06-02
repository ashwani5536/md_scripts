#bin/bash
#
echo "you are in $(pwd)"
in_pdb=${1?Error: please give pdb file name}
echo "given file name is $in_pdb"

#### strip .pdb from name###
mod_pdb=${in_pdb%.pdb}

##############################################
#
####check pdb availibility in directory###
#
##############################################

if [ -f "$in_pdb" ]
then 
     echo "$in_pdb exists at $(pwd)"
else
     echo "$in_pdb does not exist and will be downloaded from RCSB"
     wget  https://files.rcsb.org/download/$in_pdb
fi

##############################################
#
####check mdp file availibility in directory###
#
##############################################

list="ions.mdp  em.mdp  nvt.mdp npt.mdp md.mdp"
for var in $list
do 
	if [ -f "$var" ]
       then 
            echo "Following mdp exists in $(pwd); $var"
      else
           echo "$var does not exist and will be downloaded from mdtutorials"
          wget  http://www.mdtutorials.com/gmx/complex/Files/$var
  fi
done
echo "Following mdp files are available in directory:  "$(ls *.mdp)

read -p "Check (tc-grps) in nvt, npt and md.mdp, Press [Enter] key"

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

cd $mod_pdb/md_run

tmp1=_clean.pdb
tmp2=$mod_pdb$tmp1
grep -v HOH $in_pdb > $tmp2
echo "water is removed from $in_pdb file and new file with name $tmp2 is created"

##############################################
#
#### Topology file will be generated with 'pdb2gmx' command##
#
##############################################

tmp3=_processed.gro
tmp4=$mod_pdb$tmp3
gmx pdb2gmx -f $tmp2 -o $tmp4 -ff charmm36-mar2019 -water tip3p
echo "Topology file $tmp4 generated"

##############################################
#
### Box defining for protein in simulation##
# example boxes are: cubic, dodecahedron etc.
##############################################

tmp5=_newbox.gro
tmp6=$mod_pdb$tmp5
#gmx editconf -f $tmp4 -o $tmp6 -c -d  1.0 -bt cubic
gmx editconf -f $tmp4 -o $tmp6 -c -d  1.0 -bt dodecahedron
##############################################
#
###Filling water in box!!!##
#
##############################################

tmp7=_solv.gro
tmp8=$mod_pdb$tmp7
gmx solvate -cp $tmp6 -cs spc216.gro -o $tmp8 -p topol.top
echo "box generation and solvation completed, also topology file updated to reflect the added number on water in topol.top"
echo "solvent configuration file:$tmp8 " 

##############################################
#
###Adding ions to neutralizing the excess charge##
#
##############################################

gmx grompp -f ions.mdp -c $tmp8 -p topol.top -o ions.tpr -maxwarn 2

tmp9=_solv_ions.gro
tmp10=$mod_pdb$tmp9
echo 13 | gmx genion -s ions.tpr -o $tmp10 -p topol.top -pname NA -nname CL -neutral

##note: specified ion names are always the elemental symbol in all capital letters##

##############################################
#
###Energy minimization step##
#
##############################################

gmx grompp -f em.mdp -c $tmp10 -p topol.top -o em_$mod_pdb.tpr 
gmx mdrun -v -deffnm em_$mod_pdb

echo "check that Epot should be negative of order of 10**5-10**6,"

### plotting potential energy curve
echo 11 0 | gmx energy -f em_$mod_pdb.edr -o $analysis/potential_$mod_pdb.xvg
xmgrace $analysis/potential_$mod_pdb.xvg &

##############################################
#
###Protein solvent equilibration step##
#Step1--- NVT equilibration, stabilized the temperature of the system
##############################################

gmx grompp -f nvt.mdp -c em_$mod_pdb.gro -r em_$mod_pdb.gro -p topol.top -o nvt_$mod_pdb.tpr
gmx mdrun -v -deffnm nvt_$mod_pdb

###Temperature progression in mdrun during equilibration##
echo 16 0 | gmx energy -f nvt_$mod_pdb.edr -o $analysis/temperature_$mod_pdb.xvg
xmgrace $analysis/temperature_$mod_pdb.xvg &

##############################################
#
###Protein solvent equilibration step##
#Step2--- NPT equilibration, stabilized the pressure (and thus also density) of the system
##############################################

gmx grompp -f npt.mdp -c nvt_$mod_pdb.gro -r nvt_$mod_pdb.gro -t nvt_$mod_pdb.cpt -p topol.top -o npt_$mod_pdb.tpr
gmx mdrun -v -deffnm npt_$mod_pdb

###Pressure and density progression in mdrun during equilibration##
echo 17 0 | gmx energy -f npt_$mod_pdb.edr -o $analysis/pressure_$mod_pdb.xvg
xmgrace $analysis/pressure_$mod_pdb.xvg &

echo 23 0 | gmx energy -f npt_$mod_pdb.edr -o $analysis/density_$mod_pdb.xvg
xmgrace $analysis/density_$mod_pdb.xvg &

read -p "Press [Enter] key to continue or [ctr+c] to exit"
exit
##############################################
#
###Production MD##
#
#############################################

gmx grompp -f md.mdp -c npt_$mod_pdb.gro -r npt_$mod_pdb.gro -t npt_$mod_pdb.cpt -p topol.top -o md_01_$mod_pdb.tpr
gmx mdrun -v -deffnm md_01_$mod_pdb

#############################################
#
###Analysis MD##
#
#############################################

echo 0 |gmx trjconv -s md_01_$mod_pdb.tpr -f md_01_$mod_pdb.xtc -o md_01_noPBC_$mod_pdb.xtc -pbc mol -ur compact

###Output plot will show the RMSD relative to the structure present in the minimized, equilibrated system
echo 4 4 | gmx rms -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_$mod_pdb.xvg &

### Output plot of RMSD relative to the crystal structure ######
echo 4 4 | gmx rms -s em_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/rmsd_xtal_$mod_pdb.xvg -tu ns
xmgrace $analysis/rmsd_xtal_$mod_pdb.xvg &

### Output plot the radius of gyration of simulated structure ######
echo 4 | gmx gyrate -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $analysis/gyrate_$mod_pdb.xvg
xmgrace $analysis/gyrate_$mod_pdb.xvg &



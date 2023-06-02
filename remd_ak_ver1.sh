#  Replica Exchange Molecular Dynamics (t-REMD) on pdb file.
#
#            Authour:  Ashwani Kumar
#                      
#             USAGE:  sh remd_ak_ver1.sh
#             
#             Requirements:  Gromacs should be installed with mpi
#                            gfortran, gnuplot
#                          
#             
#             Description:  This script will generate required input files and run the remd simulation
#             
#             It will create following directories and stores related files in those directories:
#             
#             INITIAL_STRUCTURES:   Build the initial structures( gro & top) files
#             MIN : write necessary input files and does the energy minimization.
#             REMD: Prepare the input files for running REMD and Runs simulation for 2ns with 4 replica.
#             ANALYSIS: This script also does basic analysis and stores the plots in this directory.
#             
#             
#             Note: This script uses the geometric progression to generate the required temperatures. 
#
#
#
#




#!/bin/bash
#

function write_mdp() {
case "$1" in
  ions)
cat >> ions.mdp<<EOF
; ions.mdp - used as input into grompp to generate ions.tpr
; Parameters describing what to do, when to stop and what to save
integrator  = steep         ; Algorithm (steep = steepest descent minimization)
emtol       = 1000.0        ; Stop minimization when the maximum force < 1000.0 kJ/mol/nm
emstep      = 0.01          ; Minimization step size
nsteps      = 50000         ; Maximum number of (minimization) steps to perform

; Parameters describing how to find the neighbors of each atom and how to calculate the interactions
nstlist         = 1         ; Frequency to update the neighbor list and long range forces
cutoff-scheme	= Verlet    ; Buffered neighbor searching 
ns_type         = grid      ; Method to determine neighbor list (simple, grid)
coulombtype     = cutoff    ; Treatment of long range electrostatic interactions
rcoulomb        = 1.0       ; Short-range electrostatic cut-off
rvdw            = 1.0       ; Short-range Van der Waals cut-off
pbc             = xyz       ; Periodic Boundary Conditions in all 3 dimensions
EOF
;;
  minim)
cat >> minim.mdp<<EOF
; minim.mdp - used as input into grompp to generate em.tpr
; Parameters describing what to do, when to stop and what to save
integrator  = steep         ; Algorithm (steep = steepest descent minimization)
emtol       = 1000.0        ; Stop minimization when the maximum force < 1000.0 kJ/mol/nm
emstep      = 0.01          ; Minimization step size
nsteps      = 50000         ; Maximum number of (minimization) steps to perform

; Parameters describing how to find the neighbors of each atom and how to calculate the interactions
nstlist         = 1         ; Frequency to update the neighbor list and long range forces
cutoff-scheme   = Verlet    ; Buffered neighbor searching
ns_type         = grid      ; Method to determine neighbor list (simple, grid)
coulombtype     = PME       ; Treatment of long range electrostatic interactions
rcoulomb        = 1.0       ; Short-range electrostatic cut-off
rvdw            = 1.0       ; Short-range Van der Waals cut-off
pbc             = xyz       ; Periodic Boundary Conditions in all 3 dimensions
EOF
;;
 nvt)
cat >> nvt_$2.mdp <<EOF
title                   = amber protein remd NVT equilibration 
define                  = -DPOSRES  ; position restrain the protein
; Run parameters
integrator              = md        ; leap-frog integrator
nsteps                  = 50000     ; 2 * 50000 = 100 ps
dt                      = 0.002     ; 2 fs
; Output control
nstxout                 = 500       ; save coordinates every 1.0 ps
nstvout                 = 500       ; save velocities every 1.0 ps
nstenergy               = 500       ; save energies every 1.0 ps
nstlog                  = 500       ; update log file every 1.0 ps
; Bond parameters
continuation            = no        ; first dynamics run
constraint_algorithm    = lincs     ; holonomic constraints 
constraints             = h-bonds   ; bonds involving H are constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Nonbonded settings 
cutoff-scheme           = Verlet    ; Buffered neighbor searching
ns_type                 = grid      ; search neighboring grid cells
nstlist                 = 10        ; 20 fs, largely irrelevant with Verlet
rcoulomb                = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0       ; short-range van der Waals cutoff (in nm)
DispCorr                = EnerPres  ; account for cut-off vdW scheme
; Electrostatics
coulombtype             = PME       ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4         ; cubic interpolation
fourierspacing          = 0.16      ; grid spacing for FFT
; Temperature coupling is on
tcoupl                  = V-rescale             ; modified Berendsen thermostat
tc-grps                 = Protein Non-Protein   ; two coupling groups - more accurate
tau_t                   = 0.1     0.1           ; time constant, in ps
ref_t                   = $3     $3           ; reference temperature, one for each group, in K
; Pressure coupling is off
pcoupl                  = no        ; no pressure coupling in NVT
; Periodic boundary conditions
pbc                     = xyz       ; 3-D PBC
; Velocity generation
gen_vel                 = yes       ; assign velocities from Maxwell distribution
gen_temp                = $3       ; temperature for Maxwell distribution
gen_seed                = -1        ; generate a random seed
EOF
;;
 md)
cat >> md_$2.mdp <<EOF
title                   = amber protein md run 
; Run parameters
integrator              = md        ; leap-frog integrator
nsteps                  = 50000    ; 2 * 50000 = 100 pico.sec
dt                      = 0.002     ; 2 fs
; Output control
nstxout                 = 0         ; suppress bulky .trr file by specifying 
nstvout                 = 0         ; 0 for output frequency of nstxout,
nstfout                 = 0         ; nstvout, and nstfout
nstenergy               = 5000      ; save energies every 10.0 ps
nstlog                  = 5000      ; update log file every 10.0 ps
nstxout-compressed      = 5000      ; save compressed coordinates every 10.0 ps
compressed-x-grps       = System    ; save the whole system
; Bond parameters
continuation            = yes       ; Restarting after NPT 
constraint_algorithm    = lincs     ; holonomic constraints 
constraints             = h-bonds   ; bonds involving H are constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Neighborsearching
cutoff-scheme           = Verlet    ; Buffered neighbor searching
ns_type                 = grid      ; search neighboring grid cells
nstlist                 = 10        ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb                = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw                    = 1.0       ; short-range van der Waals cutoff (in nm)
; Electrostatics
coulombtype             = PME       ; Particle Mesh Ewald for long-range electrostatics
pme_order               = 4         ; cubic interpolation
fourierspacing          = 0.16      ; grid spacing for FFT
; Temperature coupling is on
tcoupl                  = V-rescale             ; modified Berendsen thermostat
tc-grps                 = Protein Non-Protein   ; two coupling groups - more accurate
tau_t                   = 0.1     0.1           ; time constant, in ps
ref_t                   = $3     $3           ; reference temperature, one for each group, in K
; Pressure coupling is on
pcoupl                  = Parrinello-Rahman     ; Pressure coupling on in NPT
pcoupltype              = isotropic             ; uniform scaling of box vectors
tau_p                   = 2.0                   ; time constant, in ps
ref_p                   = 1.0                   ; reference pressure, in bar
compressibility         = 4.5e-5                ; isothermal compressibility of water, bar^-1
; Periodic boundary conditions
pbc                     = xyz       ; 3-D PBC
; Dispersion correction
DispCorr                = EnerPres  ; account for cut-off vdW scheme
; Velocity generation
gen_vel                 = no        ; Velocity generation is off 
EOF
;;
 temperature)
cat >> temp.dat <<EOF
298
308.8
318.34
329.02
EOF
;;
*) echo " Invalid argument with write_mdp ";;
esac
}



#================================================================#
#Prepare Initial structure using gromacs & AMBER99SB-ILDN forcefields
#================================================================#

function Prepare_initial_structure() {

#================================================================#
#Prepare pdb and mdp files for further processing
#================================================================#


##############################################
#
####check pdb availibility in directory###
#
##############################################

if [ -f "$in_pdb" ]
then 
     echo "$in_pdb exists at $(pwd)"
     echo "================================================"
else
     echo "$in_pdb does not exist"
     exit 1   
fi


##############################################
#
###check the file for missing residues###
#
##############################################

echo "checking the file for missing residues"
echo "================================================"
if grep -q 'REMARK 465 MISSING RESIDUES' $in_pdb; then
    echo "$in_pdb has missing atom, check the file manually!!!"
    exit 1
else
     echo " file do not have missing residues"
     echo "================================================"
fi
echo "file is OK for remd simulation"
echo "================================================"

cp $in_pdb $ini
cd $ini
write_mdp ions

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
gmx pdb2gmx -f $tmp2 -o $tmp4 -ff amber99sb-ildn -ignh -water tip3p
#echo 1 | gmx pdb2gmx -f $tmp2 -o $tmp4 -water spce
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

}



##############################################
#
###Energy minimization step##
#
##############################################
function Perform_Minimisation() {

cd $wd

tmp9=_solv_ions.gro
tmp10=$mod_pdb$tmp9


if [ -d "$ini" ]
then 
    echo "== $ini == folder exist will proceed further with minimization" 
    echo "======================================================"  
else 
    echo "$ini folder does not exists, Check that initial structure processing step is performed"
    exit 1 
fi  

cd $min

cp $ini/* .   # copying the content of initial_structures folder to minimization folder 
write_mdp minim # writing min.mdp file for minimzation simulation

gmx grompp -f minim.mdp -c $tmp10 -p topol.top -o em_$mod_pdb.tpr 
gmx mdrun -v -deffnm em_$mod_pdb

echo "check that Epot should be negative of order of 10**5-10**6,"
echo "======================================================"

### plotting potential energy curve
echo 10 0 | gmx energy -f em_$mod_pdb.edr -o $analysis/potential_$mod_pdb.xvg
xmgrace $analysis/potential_$mod_pdb.xvg &

echo "======================================================"
echo "Completed the simulation part upto minimizaiton"
echo "Now REMD part of simulation can be performed"
echo "======================================================"

}

#=======================================================
# Prepare the input files for REMD simulation (NVT files for defferent Temp)
#=======================================================

function Prepare_inputs_for_remd() {

cd $wd

if [ -d "$min" ]
then 
    echo "will prepare the input steps"   
else 
    echo "$min folder does not exists, Check that minimization step is performed"
    exit 1 
fi

cd $remd

#------------------------------------------#
#awk 'BEGIN { T0=300.00; c=0.2; N=4; for (i=1; i<=N; ++i) { print T0; T0=T0*exp(i*c) }}' > temp.dat
write_mdp temperature
TEMP_FILE="temp.dat"
#
#===== Writing multiple MDP files====>>>
#
j=0
while read temp;do
#echo "$temp"
mkdir md_$j
cd md_$j
write_mdp nvt $j $temp
write_mdp md $j $temp
cp $min/*.gro .
cp $min/*.top .
cp $min/*.itp .
j=$(($j+1))
cd ..
done < $TEMP_FILE

echo "======================================================"
echo "Prepared the input files for remd simulation"
echo "======================================================"

}

function Perform_nvt_remd() {

#CREATE TPR files
##############################################
#
###Protein solvent equilibration step##
#Step1--- NVT equilibration, stabilized the temperature of the system
##############################################

cd $wd

if [ -d "$remd" ]
then 
    echo "Now will perform the nvt step"   
else 
    echo "$remd folder does not exists, Check that remd files for input are prepared"
    exit 1 
fi


cd $remd

for j in 0 1 2 3;do
cd md_$j
gmx grompp -f nvt_$j.mdp -c em_$mod_pdb.gro -r em_$mod_pdb.gro -p topol.top -o nvt_$mod_pdb-$j.tpr
gmx mdrun -v -deffnm nvt_$mod_pdb-$j -gpu_id 0 -ntmpi 1 -ntomp 12 -pin on -pinoffset 0 -pinstride 1

###Temperature progression in mdrun during equilibration##
echo 16 0 | gmx energy -f nvt_$mod_pdb-$j.edr -o $analysis/temperature_$mod_pdb-$j.xvg
xmgrace $analysis/temperature_$mod_pdb-$j.xvg &

cd ..
done

}



function Perform_md_remd() {

##############################################
###Production MD##
#############################################

cd $wd

if [ -d "$remd" ]
then 
    echo "Now will perform the md step"   
else 
    echo "$remd folder does not exists, Check that remd files for input are prepared"
    exit 1 
fi

cd $remd

for j in 0 1 2 3;do
cd md_$j
gmx grompp -f md_$j.mdp -c nvt_$mod_pdb-$j.gro -r nvt_$mod_pdb-$j.gro -t nvt_$mod_pdb-$j.cpt -p topol.top -o md_$mod_pdb.tpr
cd ..
done

############################################################
# working commands with mpi version
# np will define the number of main rank and it should be minimum the number of 
# parallel temperature run
# -ntmpi will not work with mdrun_mpi, it will work with non mpi version
# -ntomp will define the number of openMP thread for each rank(main mpi thread)
# hence total number of thread "np*ntomp" for mdrun_mpi version
# Equivalent in gmx mdrun will be "ntmpi*ntomp" threads

mpirun -np 4 mdrun_mpi -v -s md_$mod_pdb  -multidir md_[0123] -replex 500 -nsteps 50000 -gpu_id 0 -ntomp 4  -pin on -pinoffset 0 -pinstride 1


}


function Analyse_runs() {
############################################################
#   Analysis    #
############################################################

cd $remd

#   observing the replica exchange statistics
grep -A9 "average probabilities" md_[0123]/md.log > $analysis/avg_prob.log

#   Concattenate the trajectories
#   first concatenate all log file in one for demux.pl
for dir in {0..3..1}; do cp md_$dir/md.log $analysis/md_$dir.log; done
for dir in {0..3..1}; do cp md_$dir/traj_comp.xtc $analysis/traj_comp_$dir.xtc; done

cd $analysis
cat *.log > remd.log

# run demux.pl to combined log file, which will produce a file (replica_index.xvg) 
# suitable for demultiplexing your trajectories using trjcat, as well as a replica 
# temperature file (replica_temp.xvg).
#  De-multiplexing a REMD trajectory
demux.pl remd.log

# Produces the continuos coordinate trajectories

gmx trjcat -f *.xtc -demux replica_index.xvg 
echo "*_trajout.xtc files is produced in $analysis directory, which is continuous trajactory file"

xmgrace replica_index.xvg &

}



#================================================================#
#     MAIN CODE STARTS FROM HERE  
#================================================================#

echo "you are in $(pwd)"
in_pdb=${1?Error: please give pdb file name}
echo "given file name is $in_pdb"

#### strip .pdb from name###
mod_pdb=${in_pdb%.pdb}


wd=$(pwd)/$mod_pdb
analysis=$wd/md_analysis
ini=$wd/initial_structures
min=$wd/min
remd=$wd/remd

if [ -d "$wd" ]
then 
    echo "== $wd == folder exist, check you already have previous run"   
    exit 1
else 
    echo "$wd folder does not exists, new folders for $in_pdb == will be created"
    mkdir $wd $analysis $ini $min $remd
    echo "== $wd == will be working directory for $in_pdb file"
    echo "===================================================="
    echo "associated folders will be created in working directory"     
fi

Prepare_initial_structure
Perform_Minimisation
Prepare_inputs_for_remd
Perform_nvt_remd
Perform_md_remd
Analyse_runs

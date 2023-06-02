#! /bin/bash

# some useful bash commands
# command to change / replace something in file
# grep -n "nsteps" sim[0123]/sim.mdp
# sed -i -e 's/nsteps*/nsteps = 10000/' sim[0123]/sim.mdp   # replace whole line
# Command to copy 
# for dir in {0..3..1}; do cp ../stage1/equil$dir/state.cpt sim$dir/; done

# command to run grompp in multiple directory during equilibration

for dir in equil[0123]; do cd $dir; gmx grompp -f equil -c confout; cd ..; done

############################################################
# working commands with mpi version
# np will define the number of main rank and it should be minimum the number of 
# parallel temperature run
# -ntmpi will not work with mdrun_mpi, it will work with non mpi version
# -ntomp will define the number of openMP thread for each rank(main mpi thread)
# hence total number of thread "np*ntomp" for mdrun_mpi version
# Equivalent in gmx mdrun will be "ntmpi*ntomp" threads


 mpirun -np 4 mdrun_mpi -v -multidir equil[0123] -nsteps 1000000 -gpu_id 0  -ntomp 4 -pin on -pinoffset 0 -pinstride 1


############################################################

# command to run grompp in multiple directory during equilibration

for dir in sim[0123]; do cd $dir; gmx grompp -f sim -c confout -t state; cd ..; done

# mpi run for main md run

mpirun -np 4 mdrun_mpi -v -multidir sim[0123] -replex 500 -nsteps 100000 -gpu_id 0 -ntomp 4  -pin on -pinoffset 0 -pinstride 1


#############################################################
#   Analysis    #
############################################################

#   observing the replica exchange statistics

grep -A9 "average probabilities" sim[0123]/md.log > avg_prog.log

#   Concattenate the trajectories
#   first concatenate all log file in one for demux.pl
for dir in {0..3..1}; do cp sim$dir/md.log analysis/md$dir.log; done
cd analysis/
cat *.log > remd.log

# run demux.pl to combined log file, which will produce a file (replica_index.xvg) 
# suitable for demultiplexing your trajectories using trjcat, as well as a replica 
# temperature file (replica_temp.xvg).
demux.pl remd.log

#  De-multiplexing a REMD trajectory




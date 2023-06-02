#bin/bash
#
echo "you are in $(pwd)"
in_pdb=${1?Error: please give pdb file name}
echo "given file name is $in_pdb"

#### strip .pdb from name###
mod_pdb=${in_pdb%.pdb}

##############################################
#
####check that mdrun folder exist in directory###
#
##############################################

if [ -d "$mod_pdb" ]
then 
     echo "$mod_pdb folder exists in $(pwd)"
else
     echo "$mod_pdb folder does not exist, check whether MD run for pdb is performed or not "
     exit 1
fi

analysis=$(pwd)/$mod_pdb/md_analysis
run=$(pwd)/$mod_pdb/md_run

cd $run



# making directory to store pdb files with b factor values
tmp_dir=$analysis/bfacs_$mod_pdb

if [ -d "$tmp_dir" ]
then 
     echo "$tmp_dir folder exists in $(pwd)"
else
     echo "Required folder does not exist, we will create the folder "
     mkdir $tmp_dir
fi


##---------------------------------##
#____making a index file to select particular chain with hydrogen removed
#____gmx make_ndx -f md_01_6yb7.tpr -o index_6yb7.ndx
#_____ select chain A atoms by command "a 1-4682 & ! a H*"
#_____ you can rename it by command " name 18 chain_A" 
#____ here 18 is newly created group

#looping to genrate pdbs at diffrent time period

for j in {1..1000..10}
do
    i=$(( $j * 1000 ))

    echo 1 | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -ox $tmp_dir/avg.pdb -b $i -e $(( $i + 10000 )) -o $tmp_dir/rmsf_a_$mod_pdb.xvg 

    echo 18 | gmx rmsf -s $tmp_dir/avg.pdb -f md_01_noPBC_$mod_pdb.xtc -ox $tmp_dir/`printf "%0.4i.pdb\n" $j` -b $i -e $(( $i + 10000 )) -o $tmp_dir/rmsf_b_$mod_pdb.xvg -n index_6yb7.ndx

    rm -f $tmp_dir/rmsf_a_$mod_pdb.xvg
    rm -f $tmp_dir/rmsf_b_$mod_pdb.xvg
    rm -f $tmp_dir/avg.pdb

done

exit



# making directory to store pdb files with b factor values
tmp_dir=$analysis/bfacs_$mod_pdb

if [ -d "$tmp_dir" ]
then 
     echo "$tmp_dir folder exists in $(pwd)"
else
     echo "Required folder does not exist, we will create the folder "
     mkdir $tmp_dir
fi


#looping to genrate pdbs at diffrent time period

for j in {1..1000..10}
do
    i=$(( $j * 1000 ))
    echo 1 | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -ox $tmp_dir/`printf "%0.4i.pdb\n" $j` -b $i -e $(( $i + 10000 )) -o $tmp_dir/rmsf_$mod_pdb.xvg
    rm -f $tmp_dir/rmsf_$mod_pdb.xvg
done

###Output plot of RMSF relative to the structure present in the minimized, equilibrated system
#echo 1 | gmx rmsf -s md_01_$mod_pdb.tpr -f md_01_noPBC_$mod_pdb.xtc -o $tmp_dir/rmsf_$mod_pdb.xvg -ox $tmp_dir/rmsf_avg_$mod_pdb.pdb -oq $tmp_dir/rmsf_bfac_$mod_pdb.pdb -res

exit


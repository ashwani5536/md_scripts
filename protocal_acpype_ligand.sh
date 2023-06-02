#After have installed ambertools, insert the following line:
/home/username/miniconda3/envs/AmberTools21/amber.sh
in file .bashrc in your home directory (I’m not sure if amber.sh script will be in this folder, please check it location).
You can, alternatively, download and install a standalone Ambertools suite from AmberTools21 5.
If you have access to Gaussian09 (or Gaussian16) and if you like RESP charges (which is considered better charge model than bcc), you can do the following:

Optimize the geometry of your molecule using, for exemple, B3Lyp/cc-pvdz:
#P opt b3lyp/cc-pvdz geom=connectivity
Calculate MK charges of the optimized molecule using:
#P b3lyp/cc-pvdz geom=connectivity iop(6/33=2,6/41=10,6/42=17) pop=mk
Calculate RESP charges and produce Triplos mol2 file using:
antechamber -fi gout -fo mol2 -i molecule.log -o molecule.mol2 -c resp -rn MOL
(change molecule and MOL as you wish!)
create topologies files for gromacs (for GAFF, OPLS, charmm or CNS force fields) using:
acpype -i molecule.mol2 -n X -c user
where X is the charge of your molecule (it is not necessary for nonionic molecules).
That’s all!

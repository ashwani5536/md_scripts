#!/bin/bash
# script for Gromacs Installation
tar xvzf gromacs-2020.2.tar.gz
tar xvzf regressiontests-2020.2.tar.gz
cd  gromacs-2020.2/
rm -rf build # if it exist
mkdir build
cd build

cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs2020_2 -DREGRESSIONTEST_PATH=/mnt/Disk1_U18_1/linux_softwares/regressiontests-2020.2 -DGMX_GPU=ON -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-10.2

make -j 12
make check
read -p "Press [Enter] key to continue or [ctr+c] to exit"
make install

#echo "source /opt/gromacs2020_2/bin/GMXRC" >>~/.bashrc


#If you want to install with mpi support, which is not required for single workstation as has built-in thread-MPI. 
#cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs2020_2 -DREGRESSIONTEST_PATH=/mnt/Disk1_U18_1/linux_softwares/regressiontests-2020.2 -DGMX_GPU=ON -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-10.2 -DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx -DGMX_MPI=ON


#cmake .. -DCMAKE_INSTALL_PREFIX=/opt/gromacs2109_4 -DREGRESSIONTEST_PATH=/home/ashwani/Downloads/gromacs-2019.4/regressiontests -DGMX_GPU=ON -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda -DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx -DGMX_MPI=ON

#-DGMX_MPI=ON
#-DCMAKE_PREFIX_PATH=/opt/intel/impi/2019.4.243/intel64/bin
#-DCMAKE_C_COMPILER=mpicc -DCMAKE_CXX_COMPILER=mpicxx -DGMX_MPI=ON
#-DGMX_BUILD_OWN_FFTW=ON
 
#make -j N
# N is number of processors
#echo "source /opt/gromacs2109_2/bin/GMXRC" >>~/.bashrc



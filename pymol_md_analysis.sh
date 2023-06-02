## bin/bash
###script to make movie in Pymol and MD trajectory visulization

pymol protein.pdb

#After all frames have loaded, play the movie.

mplay

#While the movie is playing, all other controls still work. You can rotate the system or zoom in/out with the mouse and you can change the representation of the molecule.

spectrum

show cell

#If all is well, you now see the peptide diffusing, tumbling and wiggling. However, we're more interested in the internal motions than the overall behaviour. In Pymol you can fit all frames in the trajectory to the first one, using the command intra_fit. Subsequently, you can set the focus to the peptide with orient:

intra_fit protein

orient

#Now all frames should be superimposed and you can see that some parts of the peptide move more than other parts. This difference in motility will be quantified later on.
#Of course, the peptide would look better in cartoon representation. Try the following:

show cartoon

#This probably gives you a thick tube for the backbone, rather than proper secondary structure elements, since there is no secondary structure information in the .pdb file. Pymol can calculate the secondary structure of a protein, but will only do it for one frame and project the results on all of them. For instance, the following will calculate the secondary structure for the first frame.

dss

#Filter out high frequency atom motions (with window averaging). Type;

smooth

#By specifying a state, the frame to use for the calculations can be changed:

dss state=1000

#Finally, let's look at all frames simultaneously and check the flexible and rigid regions of the peptide.

set all_states=1

#Feel free to play around with Pymol. Try to zoom in on flexible or rigid regions and check the side-chain conformations. Feel free to waste some (CPU) time on making an image, using 'ray' and 'png' Nerd tip: export the scene to POV-Ray format and make your image even cooler Do mind that scenes that are too complex may cause the built-in ray-tracer of Pymol to crash, so in that case you can only get the image as you have it on screen using 'png' directly.

#The following part, up to 'quality assurance', is optional and it may be best to first finish the other sections.

#If you think you have plenty of time left for the remainder of the tutorial, or if you have already finished, than you may consider making a proper movie. You probably noticed that the trajectory is very noisy. That's basically thermal noise, and therefore just part of the normal behaviour, but it doesn't make very good movies. It is possible to filter out these high-frequency motions and retain only the slower and smoother global motions. For this, you can use the program g_filter:

g_filter -s topol.tpr -f traj.xtc -ol filtered.pdb -fit -nf 5

#Now load the filtered trajectory in Pymol. Set the secondary structure (dss), show the secondary structure (show cartoon), hide the lines for backbone atoms (hide lines, not (name c,n,o)) and color the peptide the way you want to have it. Then orient the molecule to set the scene. Now, you can start making a movie:

viewport 640,480

set ray_trace_frames,1

mpng frame_.png

#Now quit Pymol (quit) and list the files in the directory (ls). As you may notice, there are quite a number of files now, including 250 images. With 30 frames per second, that will make a movie of around 8 seconds. Download the program mpeg_encode and the parameter file movie.param and use it to create a movie from the individual frames (you may need to edit the parameter file to change the filenames):

mpeg_encode movie.param

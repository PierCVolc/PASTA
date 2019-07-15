* Title: Image PrepV2.atn
* Authors: Comida Pier Paolo(a), Pierre-Simon Ross
* Contact: (a) piercomida@gmail.com
* 
* DESCRIPTION: this file is an action pack for Abobe Photoshop©. It allows the user to refine a set of BSE-SEM images of epoxy-embedded juvenile particles in preparation for image analysis.
* The action pack consists of two actions: 
* 1) the first, called "Original_to_PSD_ExpCont_1pxl", converts the whole stack of BSE-SEM images from .tif format to .psd, 
* creating a temporary form layer used to refine the particle morphology. 
* The action is run from the menu File-> Scripts-> Image Processor..., selecting input and output folders, 
* and then PSD file as file type with maximizing compatibility. In part 4 of Image processor tab, select "Run Action" and select the proper action. 
* This step batch processes all the image files in the input folder;
* The user will now check and eventually refine the edge for each particle, for each image psd file. Once done, the user is strongly invited to save a backup copy before proceeding further.
* 2) In Photoshop, once the particle shape for all psd files are refined,  select all the wanted particles with the magic wand in addition mode,
* then run the action called "ClearBKG_FillHolesColorBKG" from the "Actions" menu, preferably assigning a keyboard shortcut key to speed up the process.
* 3) The psd files with blue background are used to refine the internal texture for each particle. 
* 4) Once all the psd files are refined, all the psd files are converted back into .tif format using the Image processor tab.

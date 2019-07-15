// PASTA
/*     
/* PArticle Shapes and Textures Analyzer
 * Authors: Pier Paolo Comida, Pierre-Simon Ross
 * Contact: piercomida@gmail.com
 *  
 * This script has been developed on (Fiji Is Just) ImageJ, and the use is not therefore guaranteed with the simple ImageJ app.
 * In order to work correctly, the script needs the plugin "Read and Write Excel". The plugin can be installed from the Fiji menu Help->Update
 * 
 * Description - This script allows to measure shape parameters, cristallinity and vesicularity on 2-D cross sections  
 * of juvenile particles embedded in polished grain mounts and scanned using QSBD-SEM.
 * The full processing procedure consists of three steps:
 * Step 1 - Extract single particles as separate images from input multi-particle images. Input images must have an homogeneous inter-particle area of RGB color intensity.
 * Step 2 - Single particle images are used to generate a binary form image for measuring shape parameters, and a grayscale segmented image to measure whole 2-D vesicularity and 2-D crystallinity,
 * each particle is then filtered and processed to create a binary form file and a homogeneous grayscale version of the internal texture,
 * Step 2 takes the binary form and feature grayscale files to measure shape parameters 
 * and cristallinity/vesicularity (calculated as area fraction of the whole particle area), respectively.
 * The output of the macro saved as files are:
 * - Drawing of the input multiparticle image useful to locate the particle on the sample
 * - Single particle images with the RGB background 
 * - Binary Form file of each single particle
 * - Grayscale internal texture images of each single particle
 * - An Excel spreadsheet containing the summary of the measurement, saved on the computer Desktop as "Rename me after writing is done.xlsx", 
 * 	 obtained using the Fiji plugin "Read and write Excel".
 * 	 
 * 	 For measuring the shape parameters, the script integrates and extends the functionality of the macro code 1-s2.0-S221424281500039X-mmc2.txt, 
 * 	 published by Liu, E.J., Cashman, K.V., & Rust, A.C., (2015). Optimising Shape Analysis to quantify volcanic ash morphology. GeoResJ
 * 	 
 * 	 IMPORTANT NOTE: The macro process one or multiple input images at the same time, as long as they come from the same pre-processing phase
 * 	 and have the same RGB background intensity values.
*/


/* Circularity is calculated in ImageJ as 4pi(area/perimeter^2)
* A circularity value of 1.0 indicates a perfect circle. As the value approaches 0.0, it indicates an increasingly elongated polygon.
*/ 

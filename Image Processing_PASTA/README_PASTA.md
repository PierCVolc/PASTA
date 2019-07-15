// PASTA
/*     
/* PArticle Shapes and Textures Analyzer
 * Authors: Pier Paolo Comida, Pierre-Simon Ross
 * Contact: piercomida@gmail.com
 *  OVERVIEW
 * This script has been developed on (Fiji Is Just) ImageJ, and it has not been tested with the standard version of ImageJ.
 * In order to work correctly, the script needs the plugin "Read and Write Excel". The plugin can be installed from the Fiji menu Help->Update.
 * 
 * Description - This script allows to measure shape parameters, cristallinity and vesicularity on 2-D cross sections of juvenile particles embedded in polished grain mounts and scanned using BSE-SEM.
 * The full processing procedure consists of three steps:
 * Step 1 - Extract single particles as separate images from input multi-particle images. Input images must have a homogeneously colored inter-particle area.
 * Step 2 - Single particle images are used to generate a binary form image for measuring shape parameters, and a grayscale segmented image to measure bulk 2-D vesicularity and 2-D crystallinity,
* Step 3 takes the binary form and segmented grayscale image files to measure shape and textural parameters. 
* The output of the script is:
 * - Drawing of the input multi-particle image, useful to locate the particle on the sample
 * - Single particle images with colored background 
 * - Binary form file of each particle
 * - Grayscale segmented image of each particle
 * - A summary of the measurements, saved as excel or .csv files.
 * NOTES: 
 - for measuring the shape parameters, the script integrates and extends the functionality of the macro code 1-s2.0-S221424281500039X-mmc2.txt, published by Liu, E.J., et al (2015). Optimising Shape Analysis to quantify volcanic ash morphology. GeoResJ, https://doi.org/10.1016/j.grj.2015.09.001

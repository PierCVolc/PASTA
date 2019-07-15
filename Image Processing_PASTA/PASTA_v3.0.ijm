/*  PArticle Shapes and Textures Analyzer
 *  Authors: Comida Pier Paolo(*) and Pierre-Simon Ross, Institut National de la Recherche Scientifique, 490 Rue de la Couronne, Québec, QC, Canada, G1K 9A9
 *  (*) correspondance: piercomida@gmail.com
 *   
 * This script works on (Fiji Is Just) ImageJ, and the use is not therefore guaranteed with the simple ImageJ app.
 * Plugins to be installed for the macro to work correctly are: i) Read and Write Excel, ii)
 * 
 * Description - This macro allows to measure shape parameters, cristallinity and vesicularity from 2-D surface of  
 * juvenile particles embedded in polished grain mounts and scanned using QSBD-SEM.
 * The macro requires minimal user actions just at the beginning of the process.
 * The input images to be fed in the macro are pre-processed version of the original
 * output from the SEM, when the background (area between the particles) has been cleaned and
 * substituted with a homogeneous, RGB background color while the particles are in grayscale.
 * The macro consists of three main phases organized in two steps:
 * Step 1 extract the single particles from the input multiparticle image,
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
 * 	 and have the same RGB intensity values for the background (inter-particle area).
*/


/* Circularity is calculated in ImageJ as 4pi(area/perimeter^2)
* A circularity value of 1.0 indicates a perfect circle. As the value approaches 0.0, it indicates an increasingly elongated polygon.
*/ 

print("\\Clear");

#@ File (label = "Input images", style = "directory") input
#@ File (label = "Main Output folder", style = "directory") output
#@ String (label = "Image file suffix", value = ".tif") suffix
#@ String(label = "Image type format (*)", choices={"8-bit", "RGB Color"}, style="listBox") itype
#@ String (visibility=MESSAGE, value="(*) Optional for Measurements ONLY", required=false) Optionalnote

//--- INITIAL DIALOG BOX FOR PROCESSING SETTINGS
	Dialog.create("Script processing settings");
	//--- Create initial dialog box
	Dialog.setInsets(0, 0, 0);
	// First part allows to select the steps to be run
  	Dialog.setInsets(0, 0, -10);
	Dialog.addMessage("SELECT STEPS OF THE SCRIPT TO BE EXECUTED");
  	items1 = newArray("Yes		", "No");
  	Dialog.addRadioButtonGroup("1. Isolate single particles (Select \"No\" "+
  	"if single particle images are available)", items1, 1, 2, "Yes		");
  	
	Dialog.setInsets(0, 12, 0);
	items2 = newArray("Particle shapes", "Crystallinity - Vesicularity		", "Both", "Off");
  	Dialog.addRadioButtonGroup("2. Image processing", items2, 1, 4, "Both");
	
 	Dialog.setInsets(0, 12, 0);
	items3a = newArray("Particle shapes", "Crystallinity - Vesicularity		", "Both", "Off");
  	Dialog.addRadioButtonGroup("3a. Measurements", items3a, 1, 4, "Both");
  	
	Dialog.setInsets(0, 12, -5);
	items3b = newArray("Excel(*)		", "CSV", "Both", "Off");
  	Dialog.addRadioButtonGroup("3b. Save results spreadsheet (Requires 3a to be active)", items3b, 1, 4, "CSV");
  	Dialog.setInsets(0, 40, -15);
  	Dialog.addMessage("(*) Saved on Desktop as: Rename me after writing is done.xlsx");
 	
 	Dialog.setInsets(0, 0, -5);	
	Dialog.addMessage("_________________________________________________________________________________________________________________");
	/*Second part concerns the extraction of the internal features,
	 * which will enabled only if Step 1 is active
	 */
	Dialog.setInsets(0, 0, 0);
	Dialog.addMessage("IMAGE PROCESSING SETTINGS for Crystallinity - Vesicularity (Applied if Step 2 Crystallinity - Vesicularity are processed)");
	Dialog.setInsets(0, 12, 0);
	Dialog.addCheckbox("Vesicles", true);
	Dialog.setInsets(-5, 40, -5);
	Dialog.addNumber("Minimum pixel size extraction:", 4);
	Dialog.addToSameRow();
	Dialog.addString("Label (one word):", "VES", 10);

	Dialog.setInsets(5, 12, 0);
	Dialog.addCheckbox("Oxides", true);
	Dialog.setInsets(-5, 40, -5);
	Dialog.addNumber("Minimum pixel size extraction:", 4);
	Dialog.addToSameRow();
	Dialog.addString("Label (one word):", "oxides", 10);
	
	Dialog.setInsets(5, 12, 0);
	Dialog.addCheckbox("Gray crystals 1", true);
	Dialog.setInsets(-5, 40, -5);
	Dialog.addNumber("Minimum pixel size extraction:", 20);
	Dialog.addToSameRow();
	Dialog.addString("Label (one word):", "darkXLS", 10);	

	Dialog.setInsets(5, 12, 0);
	Dialog.addCheckbox("Gray crystals 2", true);
	Dialog.setInsets(-5, 40, -5);
	Dialog.addNumber("Minimum pixel size extraction:", 20);
	Dialog.addToSameRow();
	Dialog.addString("Label (one word):", "medXLS", 10);	

	Dialog.setInsets(5, 12, 0);
	Dialog.addCheckbox("Gray crystals 3", false);
	Dialog.setInsets(-5, 40, -5);
	Dialog.addNumber("Minimum pixel size extraction:", 20);
	Dialog.addToSameRow();
	Dialog.addString("Label (one word):", "lightXLS", 10);	
	
 	Dialog.setInsets(-5, 0, -5);	
	Dialog.addMessage("_________________________________________________________________________________________________________________");	
	
	Dialog.setInsets(0, 0, 0);
	Dialog.addMessage("GRAYSCALE VALUES FOR OUTPUT SEGMENTED IMAGES");
	Dialog.setInsets(-5, 0, 0);
	Dialog.addMessage("(NOTE: if using only the measurement function with custom images, the following values MUST match those of the processed images)");
	Dialog.addNumber("Vesicles:", 0); // Set the grayscale intensity for the vesicles
	Dialog.addToSameRow();
	Dialog.addNumber("All crystals (includes oxides):", 200); // Set the grayscale intensity for the crystals
	Dialog.addToSameRow();
	Dialog.addNumber("Groundmass:", 120); // Set the grayscale intensity for the groundmass
	//Dialog.addToSameRow();
	Dialog.addNumber("Background:", 255); // Set the grayscale intensity for the background/outside particle
 	Dialog.setInsets(0, 250, 0);	
	Dialog.addMessage("(Example of grayscale values: 0 = Black ; 120 = Dark gray ; 200 = Light gray ; 255 =  White)");
	
	//---  Show the dialog box, creating the following variables for each entry
	Dialog.show();
	
	// PART 1
	rbut1 = Dialog.getRadioButton(); // Step 1 - Isolate particles
	rbut2 = Dialog.getRadioButton(); // Step 2 - Image processing
	rbut3a = Dialog.getRadioButton(); // Step 3a - Measurements
	rbut3b = Dialog.getRadioButton(); // Step 3b - Save results spreadsheet

	// PART 2
	chbVES = Dialog.getCheckbox(); // Vesicles Checkbox
	VESpse = Dialog.getNumber();   // Vesicles min. pixel size extraction
	LVES = Dialog.getString();    // Vesicles Label

	chbOXX = Dialog.getCheckbox(); // Oxides Checkbox
	OXXpse = Dialog.getNumber();   // Oxides min. pixel size extraction
	LOXX = Dialog.getString();    // Oxides Label
	
	grXLS1 = Dialog.getCheckbox(); // Gray Crystals 1 checkbox
	XLS1pse = Dialog.getNumber(); // Gray Crystals 1 min pixel size extraction
	LXLS1 = Dialog.getString(); // Gray Crystals 1 label

	grXLS2 = Dialog.getCheckbox(); // Gray Crystals 2 checkbox
	XLS2pse = Dialog.getNumber(); // Gray Crystals 2 min pixel size extraction
	LXLS2 = Dialog.getString(); // Gray Crystals 2 label

	grXLS3 = Dialog.getCheckbox(); // Gray Crystals 3 checkbox
	XLS3pse = Dialog.getNumber(); // Gray Crystals 3 min pixel size extraction
	LXLS3 = Dialog.getString(); // Gray Crystals 3 label

	// PART 3
	gfv = Dialog.getNumber(); // Grayscale value segmented image for vesicles
	gfc = Dialog.getNumber(); // Grayscale value segmented image for crystals
	gfo = Dialog.getNumber(); // Grayscale value segmented image for groundmass
	bkg = Dialog.getNumber(); // Grayscale value segmented image for background

	// Print Initial parameters
	if (rbut2 != "Off") {
		// PART 2
		print("Image processing settings:");
		if (chbVES == true) {
			print(LVES, " - min. pixel size extraction: ", VESpse);
		}
		if (chbOXX == true) {
			print(LOXX, " - min. pixel size extraction: ", OXXpse);
		}
		if (grXLS1 == true) {
			print(LXLS1, " - min. pixel size extraction: ", XLS1pse);
		}
		if (grXLS2 == true) {	
			print(LXLS2, " - min. pixel size extraction: ", XLS2pse);
		}
		if (grXLS3 == true) {	
			print(LXLS3, " - min. pixel size extraction: ", XLS3pse);
		}
		print("");
	}	
		// PART 3
		print("Grayscale values for segmented images:");
		print("Vesicles: ", gfv);
		print("Crystals: ", gfc);
		print("Groundmass: ", gfo);
		print("Background (Area outside the particle): ", bkg);
		print("");


//--- END OF INITIAL DIALOG BOX


run("Clear Results");

//--- Create new folders for single particle images, form files and drawings

	//--- 1. Isolate single particles	
			myDir1 = output+File.separator+"RGB_Singles";
		if (rbut1 == "Yes		") {
			// Create folder for single particles images with RGB background
			if (File.exists(myDir1)) {
				// do nothing
			} else {
				File.makeDirectory(myDir1);
			}

			// Create folder for drawings
			myDir2 = output+File.separator+"Input_Drawings";
			if (File.exists(myDir2)) {
				// do nothing
			} else {
				File.makeDirectory(myDir2);
			}
		}
	// ----

	// --- 2. Image processing 
			fDir = output+File.separator+"FORM";
		if (rbut2 == "Particle shapes" || rbut2 == "Both") {
			// Create folder for FORM
			if (File.exists(fDir)) {
				// do nothing
			} else {
				File.makeDirectory(fDir);
			}
		}
	
		/*Create folder for SEGMENTED
		 * i.e., a grayscale version of a single particle image with the filtered internal phases
		 * homogeneized to have a single, different grayscale intensity
		 */
			sDir = output+File.separator+"SEGMENTED";
		if (rbut2 == "Crystallinity - Vesicularity		" || rbut2 == "Both") {
			if (File.exists(sDir)) {
				// do nothing
			} else {
				File.makeDirectory(sDir);
			}
		}
	// ---	
//------------

//--- STEP 1 - ISOLATE SINGLE PARTICLES

	if(rbut1 == "Yes		") {
	print("Start Step 1 -  Isolate single particles");
	
	roiManager("reset");
	run("Clear Results");
	setBatchMode(true); //This line hides the opening of the images during processing
	
	//--- Start Main loop that process the input, multi-particle image files
	Imagefiles = getFileList(input);
	Imagefiles = Array.sort(Imagefiles);

	if (Imagefiles.length == 0) { // Check if input folder is empty: if yes, it aborts the script and displays an error message
		exit("SCRIPT ABORTED: Input folder is empty");
	}
	
	print("Number of files in the Input folder:", Imagefiles.length);
	for (i = 0; i < Imagefiles.length; i++) {
		if(endsWith(Imagefiles[i], suffix)){
		print("Processing: " + input + File.separator + Imagefiles[i]);
	
	    //-- Open the file
		open(input+File.separator+Imagefiles[i]);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Select None");
	    title=getTitle();
	    SummaLab = Imagefiles[0];
	
		/*--- Select RGB intensities. This is done only on the first input image of the whole stack,
		 * assuming all images have the same RGB background intensity values
		 */
		if (isOpen(Imagefiles[0])) {
			setBatchMode("show");
			run("Point Tool...", "type=Hybrid color=Yellow size=Medium auto-measure");
			setTool("point");
				//--- Picking RGB intensities for the background (outside particles)
				checkRGB = "No";
				chkite = newArray("Yes", "No");
				while (checkRGB == "No") {
					run("Clear Results");
					waitForUser("Pick RGB Background","Click with the cursor anywhere outside the particles."+
					"\n \nOnce done, press OK.");	
					while (selectionType()==-1) { // Warning message in case the background has not been selected.
						waitForUser("WARNING: Selection required", "A background selection is required to proceed."+
						"\nPlease move the pointer everywhere in the background to select it.");
					}	
					x=getResult("X", 0);
					y=getResult("Y", 0);
					run("Clear Results");
					v = getPixel(x, y);
					r = (v>>16)&0xff;  // extract red byte (bits 23-17)
					g = (v>>8)&0xff; // extract green byte (bits 15-8)
					b = v&0xff;       // extract blue byte (bits 7-0)
	
					//--- Check RGB background dialog box
						Dialog.create("RGB background control check");
						Dialog.setInsets(0, 10, 0);
						Dialog.addMessage("Picked RGB values:  R: "+r+" ; G: "+g+" ; B: "+b);
						Dialog.setInsets(0, 10, 0);
						Dialog.addMessage("(If image type is 8-bit, read value B only)");
						Dialog.addRadioButtonGroup("Is the correct RGB background?", chkite, 1, 2, "Yes");
						Dialog.show();
						checkRGB = Dialog.getRadioButton();
					//----------------------------------------------------------------
					if (checkRGB == "Yes") {
					print("RGB intensity values for image background: ", "R: "+r+" ;", "G: "+g+" ;", "B: "+b);
					setBatchMode("hide"); 		
					}	//--- End of RGB picking
				} // while loop checkRGB
					
		} // --- End of RGB selection	

		start = getTime(); //Compute the execution time required to process the files
	
		//--- Start of automated processing
		//-- Main loop---Open Whole image and save main drawing
		run("Duplicate...", "title=duplicate"+suffix); //duplicate the whole image to execute the process

			//--- Start Thresholding with check if image is in a RGB or grayscale format
			if (itype == "8-bit") {
				//--- Image is in grayscale format, run simple threshold
				resetThreshold(); 
				setThreshold(b, b);
				run("Invert");
				//print("Entered Grayscale thresholding");			
				//--- End of simple thresholding
			} else {
				/*--- Image is in RGB format, Start Color Thresholding (version 2.0.0-rc-68/1.52h); 
				select the background, then convert to a mask on which the particle analyzer can operate
				 */
				{ 
				min=newArray(3);
				max=newArray(3);
				filter=newArray(3);
				a=getTitle();
				run("RGB Stack");
				run("Convert Stack to Images");
				selectWindow("Red");
				rename("0");
				selectWindow("Green");
				rename("1");
				selectWindow("Blue");
				rename("2");
				min[0]=r;
				max[0]=r;
				filter[0]="pass";
				min[1]=g;
				max[1]=g;
				filter[1]="pass";
				min[2]=b;
				max[2]=b;
				filter[2]="pass";
				for (i1=0;i1<3;i1++){
				  selectWindow(""+i1);
				  setThreshold(min[i1], max[i1]);
				  run("Convert to Mask");
				  if (filter[i1]=="stop")  run("Invert");
				}
				imageCalculator("AND create", "0","1");
				imageCalculator("AND create", "Result of 0","2");
				for (i2=0;i2<3;i2++){
				  selectWindow(""+i2);
				  close();
				}
				selectWindow("Result of 0");
				close();
				selectWindow("Result of Result of 0");
				rename(a);
				//print("Entered Colour thresholding");
				}
				//--- End of Colour Thresholding-------------
				setThreshold(0, 0);

			} //--- End of Thresholding

					/* the analyzer count the single particles and add them to the ROI manager, 
					 *  excluding those ones touching the edge 
					 */
					run("Analyze Particles...", "size=0-Infinity show=Outlines exclude add");
					
					selectWindow("duplicate"+suffix);			
					close();
					selectWindow(title);
	
						
					//2nd loop; Extract single particle per image in a new File.
					/*
					 The increase of the canvas size consecutively on the top left and bottom right corners
					 solve the problems related to an error generated when isolating 
					 perfect geometric shapes such as rectangles and squares,
					 for which the lack of background causes the code to lose the current particle selection
					 */
	
					count = roiManager("count");
					for (i3 = 0; i3 < count; i3++) {
						roiManager("select", i3);
						index = roiManager("index");
						roiManager("Rename",index+1);
						roiLabel = getInfo("selection.name");
						roiLabel = parseInt(roiLabel);

						// START roiLabel Numbering
						if (count < 10) {
							//print("1; ", roiLabel);
						} else if (count >= 10 && count < 100) {
							if (roiLabel < 10){
								roiLabel = "0"+roiLabel;
								//print("2; ", roiLabel);
							}	
						} else if (count >= 100 && count < 1000) {
							if (roiLabel < 10){
								roiLabel = "00"+roiLabel;
								//print("3; ", roiLabel);
							} else if (roiLabel >= 10 && roiLabel < 100){
								roiLabel = "0"+roiLabel;
								//print("4; ", roiLabel);		 
							}	
						} else if (count >= 1000 && count < 10000) {
							if (roiLabel < 10){
								roiLabel = "000"+roiLabel;
								//print("5; ", roiLabel);
							} else if (roiLabel >= 10 && roiLabel < 100){
								roiLabel = "00"+roiLabel;
								//print("6; ", roiLabel);		 
							} else if (roiLabel >= 100 && roiLabel < 1000){
								roiLabel = "0"+roiLabel;
								//print("7; ", roiLabel);		 
							}
						} else if (count >= 10000) {
							if (roiLabel < 10){
								roiLabel = "0000"+roiLabel;
								//print("8; ", roiLabel);
							} else if (roiLabel >= 10 && roiLabel < 100){
								roiLabel = "000"+roiLabel;
								//print("9; ", roiLabel);		 
							} else if (roiLabel >= 100 && roiLabel < 1000){
								roiLabel = "00"+roiLabel;
								//print("10; ", roiLabel);		 
							}		 
						}	// END roiLabel Numbering code

						run("Duplicate...", "title=RGB_orig");
						setForegroundColor(r, g, b);
						setBackgroundColor(r, g, b);					
				
						//-- Resize RGB_orig image
							selectWindow("RGB_orig");
							run("Select None");
							run("Restore Selection");
							wp=getWidth()+20;
							hp=getHeight()+20;
							run("Canvas Size...", "width=wp height=hp position=Top-Left");
							run("Restore Selection");
							run("Make Inverse");
							run("Fill", "slice");
							run("Make Inverse");
							cwp=wp+20;
							chp=hp+20;
							run("Canvas Size...", "width=cwp height=chp position=Bottom-Right");
						//-------------------------

						//--- Save single particle images with RGB background
							orgb=replace(title, suffix, "-"+roiLabel+suffix);
							rename(orgb);
							saveAs("TIFF",myDir1+File.separator+orgb);
							close();
						//--------				
					}
					
				//-- Save out the drawing of the input image
					selectWindow("Drawing of duplicate"+suffix);
					drawg=replace(title, suffix, "_drawing"+suffix);
					rename(drawg);
				    saveAs("TIFF",myDir2+File.separator+drawg);
				    roiManager("reset");
					close();
				//-----
			// End of the processing of one input image (if loop)
		} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files");
		} 
		 
	//-- Close everything before the next image is opened
	close("*");
	run("Close All");

} // End of the processing of one input image (for loop)	    
		    
print("End of Step 1");
} else {
	print("Step 1 - Isolate particles: OFF");
}

//---------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------
print(""); // Create a space line in the Log between the two steps
close("*");
run("Close All");
run("Clear Results");

// STEP 2 - IMAGE PROCESSING	

if (rbut2 != "Off") {

print("Start Step 2 - Image processing");

roiManager("reset");
run("Clear Results");

if (rbut1 == "No") { // If Step 1 is not running, the following code make up for the missing portions of the code
		if (File.exists(myDir1)) { // Check if RGB single files folder is present in the output folder 
			// continue
		} else if (File.exists(input+File.separator+"RGB_Singles")) { // Check for a "RGB_Singles" folder in the main INPUT folder
			myDir1 = input+File.separator+"RGB_Singles";
			print(myDir1);
		} else { // Otherwise, it takes the INPUT folder as  the main location for the files
			myDir1 = input;
			print(myDir1);
			}
	//print("executing this");

// --- RGB background Picking if Step 1 is off
pickList0 = getFileList(myDir1);
pickList0 = Array.sort(pickList0);

if (pickList0.length == 0) { // Check if input folder is empty: if yes, it aborts the script and displays an error message
	exit("SCRIPT ABORTED: Input folder is empty");
}

for (i = 0; i < pickList0.length; i++) {
	if(endsWith(pickList0[i], suffix)){
	} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files");
		} 		
}
open(myDir1+File.separator+pickList0[0]);
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
run("Select None");
run("Point Tool...", "type=Hybrid color=Yellow size=Medium auto-measure");
setTool("point");
	//--- Picking RGB intensities for the background (outside particles)
	checkRGB2 = "No";
	chkite2 = newArray("Yes", "No");
	while (checkRGB2 == "No") {
		run("Clear Results");
		waitForUser("Pick RGB Background","Click with the cursor anywhere outside the particles."+
		"\n \nOnce done, press OK.");	
		while (selectionType()==-1) { // Warning message in case the background has not been selected.
			waitForUser("WARNING: Selection required", "A background selection is required to proceed."+
			"\nPlease move the pointer everywhere in the background to select it.");
			wait
		}	
		x2=getResult("X", 0);
		y2=getResult("Y", 0);
		v2 = getPixel(x2, y2);
		run("Clear Results");
		r = (v2>>16)&0xff;  // extract red byte (bits 23-17)
		g = (v2>>8)&0xff; // extract green byte (bits 15-8)
		b = v2&0xff;       // extract blue byte (bits 7-0)

		//--- Check RGB background dialog box
			Dialog.create("RGB background control check");
			Dialog.setInsets(0, 10, 0);
			Dialog.addMessage("Picked RGB values:  R: "+r+" ; G: "+g+" ; B: "+b);
			Dialog.setInsets(0, 10, 0);
			Dialog.addMessage("(If image type is 8-bit, read value B only)");
			Dialog.addRadioButtonGroup("Is the correct RGB background?", chkite2, 1, 2, "Yes");
			Dialog.show();
			checkRGB2 = Dialog.getRadioButton();
		//----------------------------------------------------------------
		if (checkRGB2 == "Yes") {
		print("RGB intensity values for image background: ", "R: "+r+" ;", "G: "+g+" ;", "B: "+b);
		close();
		setBatchMode("hide"); 		
		}	//--- End of RGB picking
	} // while loop checkRGB					
		
} // End of "if" loop when step 1 is OFF

//--- Pick intensity values for internal features				
if (rbut2 == "Crystallinity - Vesicularity		" || rbut2 == "Both") {

	if (chbVES == true || chbOXX == true || grXLS1 == true || grXLS2 == true || grXLS3 == true) {
		
		featsel = "null";
		//print("483 featsel", featsel);
		//print("-----------");
		trsel = false;
		
		while (trsel == false) {
		
			if (featsel == "null") {
				waitForUser("Crystallinity - Vesicularity Threshold selection - Intro", "For each internal feature (vesicles, oxides, crystals, etc.),"+
				" you have to select the threshold values."+
				"\n \nThreshold selection works through two dialog boxes, in the following order:"+
				"\n \n1) In the \"Image & feature selector\" menu, choose the feature to be thresholded"+
				"\n    and the sample image, then click Ok"+
				"\n2) Now follow the directions in the \"Instructions\" box to pick"+
				"\n    the threshold intensity values, then press Ok when done"+
				"\n3) Once all features have been selected, check the \"Exit\" box"+
				"\n    at the bottom of the \"Image & feature selector\" menu to end threshold selection and continue"+
				"\n \nPress Ok to start.");
			}
		
					//--- Dialog Box: Image selector initial conditions
					if (featsel == "null") {
						if (chbVES==true) {
							L1 = LVES;
							itemssel = newArray(L1);	
							n1 = 1;
						} else {
							n1 = 0;
							L1 = newArray();
						}
					
						if (chbOXX==true) {	
							L2 = LOXX;
							itemssel = Array.concat(L1, L2);
							n2 = 1;
						} else {
							n2 = 0;
							L2 = newArray();
						}
					
						if (grXLS1==true) {
							L3 = "Gray crystal 1 ("+LXLS1+")  ";
							itemssel = Array.concat(L1, L2, L3);
							n3 = 1;
						} else {
							n3 = 0;
							L3 = newArray();
						}
					
						if (grXLS2==true) {
							L4 = "Gray crystal 2 ("+LXLS2+")  ";
							itemssel = Array.concat(L1, L2, L3, L4);
							n4 = 1;
						} else {
							n4 = 0;
							L4 = newArray();
						}
					
						if (grXLS3==true) {
							L5 = "Gray crystal 3 ("+LXLS3+")  ";
							itemssel = Array.concat(L1, L2, L3, L4, L5);
							n5 = 1;
						} else {
							n5 = 0;
							L5 = newArray();
						}
					
						ntot = n1 + n2 + n3 + n4 + n5;
						print("Number of active features: "+ntot);¸
						Array.print(itemssel);

		
						/* --- This portion of code allow to start the below dialog box already with the first 
						 *  of the active internal feature selected
						 */
						//Array.print(items);
						//featsel = Array.trim(items, 1);
						//Array.show("Results", featsel);
						//featsel = getResultString("Value", 0);
						//run("Clear Results");
						//print(featsel);
						//---------------------------------------------------------------------------------
						
						ftVESmin = 0;
						ftVESmax = 5;
						ftOXXmin = 250;
						ftOXXmax = 255;
						ftgrXLS1min = 60;
						ftgrXLS1max = 118;
						ftgrXLS2min = 72;
						ftgrXLS2max = 160;
						ftgrXLS3min = 85;
						ftgrXLS3max = 200;
					
					
						n0 = 0;
						numb = 0;
						//print("577 numb:", numb);
					} // ------------------------------------------- 

					pickList = getFileList(myDir1);
					pickList = Array.sort(pickList);
					pickL = pickList.length;
					//--- Image selector dialog box For loop
					for (i = 0; i < pickList.length; i++) {
						if(endsWith(pickList[i], suffix)){
							if (trsel == false) {
								featsel1 = featsel;
								//print("589 featsel1", featsel1);
								//--- Dialog Box: Image selector
								Dialog.create("Threshold selection: Image & feature selector");
								
					  			Dialog.addRadioButtonGroup("1. Select feature to threshold", itemssel, 1, ntot, featsel);
								Dialog.setInsets(-10, 10, 0);
					 			Dialog.addMessage("__________________________________________________________________________________________________________");			
								Dialog.setInsets(0, 10, 0);					 			
					 			Dialog.addMessage("2. Select a typical image from the single particle folder (Enter a number or use the scroll bar)");	
								Dialog.addSlider("", n0+1, pickL, numb);
								Dialog.setInsets(-10, 10, 0);	
								Dialog.addMessage("__________________________________________________________________________________________________________");
								Dialog.setInsets(0, 10, 0);									
								Dialog.addMessage("3. Now click \"OK\" at the bottom to enter threshold selection");
								Dialog.setInsets(-10, 10, 0);		
								Dialog.addMessage("__________________________________________________________________________________________________________");
								Dialog.setInsets(-15, 10, 0);		
								Dialog.addMessage("__________________________________________________________________________________________________________");								
								Dialog.addMessage("FINAL THRESHOLD VALUES");
								Dialog.setInsets(10, 20, 0);									
								Dialog.addMessage("Enter threshold values for feature extraction");					
								
								Dialog.setInsets(0, 20, 0);
								if (chbVES==true) { // Vesicles
									Dialog.setInsets(0, 30, 0);
									Dialog.addMessage("Vesicles ("+LVES+")");
									Dialog.setInsets(0, 30, 0);
									Dialog.addNumber("Min:", ftVESmin);
									Dialog.addToSameRow();	
									Dialog.addNumber("Max:", ftVESmax);
								}
							
								if (chbOXX==true) { // Oxides
									Dialog.setInsets(0, 20, 0);
									Dialog.addMessage("Oxides ("+LOXX+")");
									Dialog.setInsets(0, 30, 0);
									Dialog.addNumber("Min:", ftOXXmin);
									Dialog.addToSameRow();			
									Dialog.addNumber("Max:", ftOXXmax);
								}
								
								Dialog.setInsets(10, 20, 0);
								Dialog.addMessage("Gray Crystals");				
								if (grXLS1==true) { // Gray Crystals 1		
									Dialog.setInsets(0, 40, 0);
									Dialog.addNumber("1 ("+LXLS1+") ;   Min:", ftgrXLS1min); 
									Dialog.addToSameRow();			
									Dialog.addNumber("Max:", ftgrXLS1max);
								}
							
								if (grXLS2==true) { // Gray Crystals 2
									Dialog.setInsets(0, 40, 0);		
									Dialog.addNumber("2 ("+LXLS2+") ;   Min:", ftgrXLS2min); 
									Dialog.addToSameRow();			
									Dialog.addNumber("Max:", ftgrXLS2max);
								}
							
								if (grXLS3==true) { // Gray Crystals 3							// Line 1a	
									Dialog.setInsets(0, 40, 0);									// Line 1b
									Dialog.addNumber("3 ("+LXLS3+") ;   Min:", ftgrXLS3min); 	// Line 1c		
									Dialog.addToSameRow();										// Line 1d		
									Dialog.addNumber("Max:", ftgrXLS3max); 						// Line 1e
								}
								Dialog.setInsets(-10, 10, 0);
								Dialog.addMessage("__________________________________________________________________________________________________________");
								Dialog.setInsets(-15, 10, 0);		
								Dialog.addMessage("__________________________________________________________________________________________________________");	
								Dialog.setInsets(10, 10, 0);
								Dialog.addMessage("EXIT>> Once threshold values for each feature have been acquired,"+
								" check the box below and press Ok to exit threshold selection.");
								Dialog.setInsets(0, 25, 0);
								Dialog.addCheckbox("Check to exit.", false);
								
								Dialog.show();
					
								featsel = Dialog.getRadioButton();
								//print("664 featsel", featsel);
								
								numb = Dialog.getNumber(); // virtual number of the image
								//print("667 numb:", numb);
								numb2 = numb-1; // Actual, sequential number of the image from the folder list (starts from 0)
								//print("669 numb2:", numb2);
								
								if (chbVES==true) { // Vesicles
									ftVESmin = Dialog.getNumber(); 
									ftVESmax = Dialog.getNumber();
								}
							
								if (chbOXX==true) { // Oxides
									ftOXXmin = Dialog.getNumber(); 
									ftOXXmax = Dialog.getNumber();
								}
							
								if (grXLS1==true) { // Gray Crystals 1	
									ftgrXLS1min = Dialog.getNumber(); 
									ftgrXLS1max = Dialog.getNumber();
								}
							
								if (grXLS2==true) { // Gray Crystals 2	
									ftgrXLS2min = Dialog.getNumber(); 
									ftgrXLS2max = Dialog.getNumber();
								}
							
								if (grXLS3==true) { // Gray Crystals 3				// Line 2a
									ftgrXLS3min = Dialog.getNumber();				// Line 2b
									ftgrXLS3max = Dialog.getNumber(); 				// Line 2c
								}													// Line 2d
							
								trsel = Dialog.getCheckbox(); // Exit check for internal feature thresholding
								if (featsel != "null") {
									if (trsel == false) {
										setBatchMode(false); // This command is needed to force the image to show
										// Open Image
										if (featsel1 == featsel) {								
											open(myDir1+File.separator+pickList[numb2]);
											run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
											run("Select None");
											//print("703 open image "+numb+" (numb) whose actual sequential number is "+numb2+" (numb2)");
										} else {
											numb = 1;
											//print("706 numb:", numb);
											numb2 = numb-1;
											//print("708 numb2:", numb2);
											open(myDir1+File.separator+pickList[numb2]);
											run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
											run("Select None");
											//print("710 open image "+numb+" (numb) whose actual sequential number is "+numb2+" (numb2)");									
										}

										//isOpen(pickList[numb2]); //check if file is open
										run("Color Threshold...");
										setTool("zoom");
										//--- Interactive message WaitForUser, that allows to operate on the image feature to be thresholded		
										waitForUser("Threshold selection: Instructions", "SELECTED FEATURE: "+featsel+
										"\n \nTo pick intensity values:"+
										"\n   1) Change the \"Color space\" mode to \"RGB\" in the Color Threshold panel"+
										"\n   2) Zoom on a typical feature"+
										"\n   3) Select your favorite selection tool (First four icons on the left side of the Fiji Toolbar)"+
										"\n   4) Select any representative area of the feature"+
										"\n   5) Click on the \"Sample\" button at the bottom of the Color Threshold panel"+
										"\n   6) Click Ok to return to the Image & feature selector menu in order to enter the values"+
										"\n       (Threshold Color Panel will stay open)");
										numb = numb+1;
										//print("722 numb:", numb);
										//print("----------");
										close();
									} // internal second if loop
								} else {
									showMessage("ATTENTION: NO feature for threshold is selected."+
									"\nPress \"OK\" to continue, then select a feature.");
								}
							} // Internal first if loop
							
						} // Main for-if loop 1
					} // Main for-if loop 2	
		
				} // End While loop	
		} else { // Exception code if no internal features are selected in the Initial dialog box
			exit("SCRIPT ABORTED: No internal features to be extracted were selected");
		} //-----------------------------------
	} // End main if statement if cristallinity-vesicularity or "both" buttons are selected
close("*");	
setBatchMode("hide");

//--- Print chosen threshold values
if (rbut2 == "Crystallinity - Vesicularity		" || rbut2 == "Both") {
	// Vesicles
	if (chbVES==true) { // Vesicles
		print("Selected Threshold values for "+LVES+": Min: "+ftVESmin+", Max: "+ftVESmax);
	} 	
	
	// Oxides
	if (chbOXX==true) { // Oxides
		print("Selected Threshold values for "+LOXX+": Min: "+ftOXXmin+", Max: "+ftOXXmax);
	}	
	
	// Gray Crystals 1
	if (grXLS1==true) { // Gray Crystals 1	
		print("Selected Threshold values for "+LXLS1+": Min: "+ftgrXLS1min+", Max: "+ftgrXLS1max);
	} 	

	// Gray Crystals 2
	if (grXLS2==true) { // Gray Crystals 2	
		print("Selected Threshold values for "+LXLS2+": Min: "+ftgrXLS2min+", Max: "+ftgrXLS2max);
	}

	// Gray Crystals 3	
	if (grXLS3==true) { // Gray Crystals 3	
		print("Selected Threshold values for "+LXLS3+": Min: "+ftgrXLS3min+", Max: "+ftgrXLS3max);
	}
}
//---------------------------


if (rbut1 == "No") {
setBatchMode(true); //This line hides the opening of the images during processing
start = getTime(); //Compute the execution time required to process the files
}


//--- Start automated Main loop that process the input, multi-particle image files
Psingles = getFileList(myDir1);
Psingles = Array.sort(Psingles);
print("Number of files in the Input folder:", Psingles.length);
	for (i = 0; i < Psingles.length; i++) {
		if(endsWith(Psingles[i], suffix)){
		print("Processing: " + myDir1 + File.separator + Psingles[i]);
	
	    //-- Open the file
		open(myDir1+File.separator+Psingles[i]);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Select None");
	    orgb=getTitle();
	    SummaLab = Psingles[0];
	    
	    // --- START IMAGE PROCESSING: PARTICLE SHAPES
	    if (rbut2 == "Particle shapes" || rbut2 == "Both") {
		//--- Create duplicate for form
			run("Duplicate...", "title=FORM");
			dupform=getTitle();			
		//-------
	
		//--- Create FORM and selection
			selectWindow(dupform);
			//--- Start Thresholding with check if image is in a RGB or grayscale format
			if (itype == "8-bit") {
				//--- If image is in grayscale format, run simple threshold
				resetThreshold(); 
				setThreshold(b, b);
				run("Invert");
				//--- End of simple thresholding
			} else {
				/*--- If image is in RGB format, Start Color Thresholding (version 2.0.0-rc-68/1.52h); 
				select the background, then convert to a mask on which the particle analyzer can operate
				 */
				{ 
				min1=newArray(3);
				max1=newArray(3);
				filter1=newArray(3);
				bct=getTitle();
				run("RGB Stack");
				run("Convert Stack to Images");
				selectWindow("Red");
				rename("0");
				selectWindow("Green");
				rename("1");
				selectWindow("Blue");
				rename("2");
				min1[0]=r;
				max1[0]=r;
				filter1[0]="pass";
				min1[1]=g;
				max1[1]=g;
				filter1[1]="pass";
				min1[2]=b;
				max1[2]=b;
				filter1[2]="pass";
				for (i21=0;i21<3;i21++){
				  selectWindow(""+i21);
				  setThreshold(min1[i21], max1[i21]);
				  run("Convert to Mask");
				  if (filter1[i21]=="stop")  run("Invert");
				}
				imageCalculator("AND create", "0","1");
				imageCalculator("AND create", "Result of 0","2");
				for (i22=0;i22<3;i22++){
				  selectWindow(""+i22);
				  close();
				}
				selectWindow("Result of 0");
				close();
				selectWindow("Result of Result of 0");
				rename(bct);
				}
				//--- End of Colour Thresholding-------------
			} //--- End of Thresholding

			//--- Generate binary FORM image file			
			run("Create Selection");
			setForegroundColor(0, 0, 0);
			run("Fill", "slice"); // Fill particle form
			run("Make Inverse");
			setForegroundColor(255, 255, 255);
			run("Fill", "slice"); // fill background
			run("Make Inverse");
			run("Make Binary");
			//-------
		
			//--- Save single particle Form binary image
				dupform=replace(orgb, suffix, "_FORM"+suffix);
				rename(dupform);
				saveAs("TIFF",fDir+File.separator+dupform);
				close();							
			//------
			
	    } //--- End of image processing: particle shapes

	    
	
	// --- START IMAGE PROCESSING: FEATURE EXTRACTION
	if (rbut2 == "Crystallinity - Vesicularity		" || rbut2 == "Both") {
	
		//--- Crystallinity-vesicularity extraction part of Step 2	
		/*  --- Create duplicates ---
		 *  This part creates duplicates of the
		 *  filtered image, one for each single feature
		 *  Repeat line 1 to 5 below for each one
		 *  of the internal features to be extracted
		 */
		selectWindow(orgb); 
		run("Select None");
	
		// Vesicles
		if (chbVES==true) {					
		run("Duplicate...", "title=&LVES");				
		dupVES=getTitle();
		}		
	
		// Oxides
		if (chbOXX==true) {
		run("Duplicate...", "title=&LOXX");
		dupOXX=getTitle();
		}
	
		// Gray Crystals 1
		if (grXLS1==true) {
		run("Duplicate...", "title=&LXLS1");
		dupXLS1=getTitle();
		}
	
		// Gray Crystals 2
		if (grXLS2==true) {
		run("Duplicate...", "title=&LXLS2");
		dupXLS2=getTitle();
		}
		
		// Gray Crystals 3						// line 1
		if (grXLS3==true) { 					// line 2
		run("Duplicate...", "title=&LXLS3");    // line 3
		dupXLS3=getTitle(); 					// line 4
		}										// line 5
		
		//print(isOpen(dupVES)); 
		//print(isOpen(dupOXX)); 		
		//print(isOpen(dupXLS1)); 		
		//print(isOpen(dupXLS2)); 
		//print(isOpen(dupXLS3)); 
	//--- Start Extraction
		/*  
		 *   Repeat Block 1 for features that can be thresholded in grayscale
		 *   Repeat Block 2 for features that require Color thresholding
		 *  
		 */
	
		//--- Extract Vesicles
		if (chbVES==true) {
			selectWindow(dupVES); // VES
			run("8-bit");
			setThreshold(ftVESmin, ftVESmax);
			run("Analyze Particles...", "size=&VESpse-Infinity circularity=0.00-1.00 show=Masks clear");
			run("Invert LUT");
			run("Create Selection");
			close(dupVES); // close duplicate for VES
			rename(dupVES);
		} //--- End Vesicle extraction
	
		//--- Extract Oxides ----------------------------------------------------------------------------- Block 1
		if (chbOXX==true) {
			selectWindow(dupOXX); //oxides
			run("8-bit");
			setThreshold(ftOXXmin, ftOXXmax);
			run("Analyze Particles...", "size=&OXXpse-Infinity circularity=0.00-1.00 show=Masks clear");
			run("Invert LUT");
			run("Create Selection");
			// Write save code here in case you desire save this file			
			close(dupOXX); // close duplicate for Oxides
			rename(dupOXX);
		} //--- End Oxides --------------------------------------------------------------------------------End of Block 1	
	
		//--- Extract Gray Crystals 1 
		if (grXLS1 == true) {
			selectWindow(dupXLS1);				
			/*
			 * The dialog box below allow to insert the threshold value for each single feature
			 * 
			 * Duplicate following lines 1 and 2 (a-e) to add an extra feature to be thresholded
			 * 
			 * The following two lines and the following if statement allow to choose the threshold
			 * intensity values for each feature on the first image of the whole sequence,
			 * and then use the same values for all the files to be processed
			 */
			//-- Color Thresholder for feature 1 2.0.0-rc-69/1.52i
				{
				min2=newArray(3);
				max2=newArray(3);
				filter2=newArray(3);
				cct=getTitle();
				run("RGB Stack");
				run("Convert Stack to Images");
				selectWindow("Red");
				rename("0");
				selectWindow("Green");
				rename("1");
				selectWindow("Blue");
				rename("2");
				min2[0]=ftgrXLS1min;
				max2[0]=ftgrXLS1max;
				filter2[0]="pass";
				min2[1]=ftgrXLS1min;
				max2[1]=ftgrXLS1max;
				filter2[1]="pass";
				min2[2]=ftgrXLS1min;
				max2[2]=ftgrXLS1max;
				filter2[2]="pass";
				for (i30=0;i30<3;i30++){
				  selectWindow(""+i30);
				  setThreshold(min2[i30], max2[i30]);
				  run("Convert to Mask");
				  if (filter2[i30]=="stop")  run("Invert");
				}
				imageCalculator("AND create", "0","1");
				imageCalculator("AND create", "Result of 0","2");
				for (i31=0;i31<3;i31++){
				  selectWindow(""+i31);
				  close();
				}
				selectWindow("Result of 0");
				close();
				selectWindow("Result of Result of 0");
				rename(cct);
				}
			//--- End of Colour Thresholding-------------
			
			run("Analyze Particles...", "size=&XLS1pse-Infinity show=Masks clear");
			run("Invert LUT");
			run("Create Selection");
				
			close(dupXLS1); // close duplicate for Gray Crystal 1
			rename(dupXLS1);	
		} //--- End Gray crystals 1 extraction 
	
		//--- Extract Gray Crystals 2
		if (grXLS2==true) {
			selectWindow(dupXLS2);
	
			//-- Color Thresholder for feature 2, 2.0.0-rc-69/1.52i
			{
			min3=newArray(3);
			max3=newArray(3);
			filter3=newArray(3);
			dct=getTitle();
			run("RGB Stack");
			run("Convert Stack to Images");
			selectWindow("Red");
			rename("0");
			selectWindow("Green");
			rename("1");
			selectWindow("Blue");
			rename("2");
			min3[0]=ftgrXLS2min;
			max3[0]=ftgrXLS2max;
			filter3[0]="pass";
			min3[1]=ftgrXLS2min;
			max3[1]=ftgrXLS2max;
			filter3[1]="pass";
			min3[2]=ftgrXLS2min;
			max3[2]=ftgrXLS2max;
			filter3[2]="pass";
			for (i32=0;i32<3;i32++){
			  selectWindow(""+i32);
			  setThreshold(min3[i32], max3[i32]);
			  run("Convert to Mask");
			  if (filter3[i32]=="stop")  run("Invert");
			}
			imageCalculator("AND create", "0","1");
			imageCalculator("AND create", "Result of 0","2");
			for (i33=0;i33<3;i33++){
			  selectWindow(""+i33);
			  close();
			}
			selectWindow("Result of 0");
			close();
			selectWindow("Result of Result of 0");
			rename(dct);
			}
			//--- End of Colour Thresholding-------------
			
			run("Analyze Particles...", "size=&XLS2pse-Infinity show=Masks clear");
			run("Invert LUT");
			run("Create Selection");			
			close(dupXLS2); // close duplicate for Gray Crystals 2
			rename(dupXLS2);
		} //--- End Gray Crystals 2 extraction
	
		//--- Extract Gray Crystals 3 ---------------------------------------------------------------------- Block 2
		if (grXLS3==true) {
			selectWindow(dupXLS3);
	
			//-- Color Thresholder for feature 2, 2.0.0-rc-69/1.52i
			{
			min4=newArray(3);
			max4=newArray(3);
			filter4=newArray(3);
			ect=getTitle();
			run("RGB Stack");
			run("Convert Stack to Images");
			selectWindow("Red");
			rename("0");
			selectWindow("Green");
			rename("1");
			selectWindow("Blue");
			rename("2");
			min4[0]=ftgrXLS3min;
			max4[0]=ftgrXLS3max;
			filter4[0]="pass";
			min4[1]=ftgrXLS3min;
			max4[1]=ftgrXLS3max;
			filter4[1]="pass";
			min4[2]=ftgrXLS3min;
			max4[2]=ftgrXLS3max;
			filter4[2]="pass";
			for (i34=0;i34<3;i34++){
			  selectWindow(""+i34);
			  setThreshold(min4[i34], max4[i34]);
			  run("Convert to Mask");
			  if (filter4[i34]=="stop")  run("Invert");
			}
			imageCalculator("AND create", "0","1");
			imageCalculator("AND create", "Result of 0","2");
			for (i35=0;i35<3;i35++){
			  selectWindow(""+i35);
			  close();
			}
			selectWindow("Result of 0");
			close();
			selectWindow("Result of Result of 0");
			rename(ect);
			}
			//--- End of Colour Thresholding-------------
			
			run("Analyze Particles...", "size=&XLS3pse-Infinity show=Masks clear");
			run("Invert LUT");
			run("Create Selection");
				
			close(dupXLS3); // close duplicate for feature 3
			rename(dupXLS3);
		} //--- End Gray Crystals 3 extraction ------------------------------------------------- End of Block 2
		
	//--- END FEATURE EXTRACTION
	
	//showMessageWithCancel("Vesicles Check","Is there a selection?");	
	
		//--- Merge single features to create one single image file with the grayscale features
		/*
		 * Repeat Block 3 for each one of the extra features added above
		 */

			//---Set base image with Groundmass
				selectWindow(orgb);

				/*--- Start Color Thresholding (version 2.0.0-rc-68/1.52h); 
				select the background, then convert to a mask on which the particle analyzer can operate
				 */
				{
				mingra=newArray(3);
				maxgra=newArray(3);
				filtergra=newArray(3);
				grai=getTitle();
				run("RGB Stack");
				run("Convert Stack to Images");
				selectWindow("Red");
				rename("0");
				selectWindow("Green");
				rename("1");
				selectWindow("Blue");
				rename("2");
				mingra[0]=r;
				maxgra[0]=r;
				filtergra[0]="pass";
				mingra[1]=g;
				maxgra[1]=g;
				filtergra[1]="pass";
				mingra[2]=b;
				maxgra[2]=b;
				filtergra[2]="pass";
				for (igra1=0;igra1<3;igra1++){
				  selectWindow(""+igra1);
				  setThreshold(mingra[igra1], maxgra[igra1]);
				  run("Convert to Mask");
				  if (filtergra[igra1]=="stop")  run("Invert");
				}
				imageCalculator("AND create", "0","1");
				imageCalculator("AND create", "Result of 0","2");
				for (igra2=0;igra2<3;igra2++){
				  selectWindow(""+igra2);
				  close();
				}
				selectWindow("Result of 0");
				close();
				selectWindow("Result of Result of 0");
				rename(grai);
				}
				//--- End of Colour Thresholding-------------
				setThreshold(0, 0);
				
				run("Create Selection");
				setForegroundColor(gfo, gfo, gfo); 
				run("Fill");
				run("Make Inverse");
				setForegroundColor(bkg, bkg, bkg); // 
				run("Fill");
				run("Select None");
				rename("segbase");
				segbase = getTitle();	
			// End Set up base grayscale image

			//--- Vesicles
			if (chbVES==true) {
				selectWindow(dupVES);
				setPasteMode("Transparent-zero");
				run("Copy");
				close();
				selectWindow(segbase);
				run("Paste");
				run("Make Inverse");
					if (selectionType()!=-1) {
						setForegroundColor(gfv, gfv, gfv);
						run("Fill");
					}
			} //--- Vesicles

			//--- Oxides
			if (chbOXX==true) {
				selectWindow(dupOXX);
				setPasteMode("Transparent-zero");
				run("Copy");
				close();
				selectWindow(segbase);
				run("Paste");
				run("Make Inverse");
					if (selectionType()!=-1) {
						setForegroundColor(gfc, gfc, gfc);
						run("Fill");
					}
			} //--- Oxides

			//--- Gray Crystals 1
			if (grXLS1==true) {
				selectWindow(dupXLS1);
				setPasteMode("Transparent-zero");
				run("Copy");
				close();
				selectWindow(segbase);
				run("Paste");
				run("Make Inverse");
					if (selectionType()!=-1) { // this loop check if a feature selection is present and fill it with the crystal phase color.
						setForegroundColor(gfc, gfc, gfc);
						run("Fill");
					} 
			} //--- Gray Crystals 1

			//--- Gray Crystals 2
			if (grXLS2==true) {
				selectWindow(dupXLS2);
				setPasteMode("Transparent-zero");
				run("Copy");
				close();
				selectWindow(segbase);
				run("Paste");
				run("Make Inverse");
					if (selectionType()!=-1) { // this loop check if a feature selection is present and fill it with the crystal phase color.
						setForegroundColor(gfc, gfc, gfc);
						run("Fill");
					} 
			} //--- Gray Crystals 2
	
			//--- Gray Crystals 3  ------------------------------------------ Block 3
			if (grXLS3==true) {
				selectWindow(dupXLS3);
				setPasteMode("Transparent-zero");
				run("Copy");
				close();
				selectWindow(segbase);
				run("Paste");
				run("Make Inverse");
					if (selectionType()!=-1) {
						setForegroundColor(gfc, gfc, gfc);
						run("Fill");
					}
			} // -------------------------------------------------------- End of Block 3
	
			run("Select None");
			resetThreshold;
			//--- Save single particles with internal features segmented in grayscale
			ftseg = replace(orgb, suffix, "_ftseg"+suffix);
			rename(ftseg);
			saveAs("TIFF",sDir+File.separator+ftseg);
			close();			
			//--- Clear results for next particle 
			run("Clear Results");
		}
	
	 } // End of particle extraction and segmentation for a input image
	}
	print("End of Step 2");
} else {
	print("Step 2 - Image processing: OFF");
}
print(""); // Create a space line in the Log between the two steps
//------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------

//--- STEP 3: MEASUREMENTS

//--- Input check for particle shapes and cristallinity - vesicularity folders
if (rbut3a != "Off") {
if (File.exists(input+File.separator+"FORM")) {
	fDir = input+File.separator+"FORM";
	// continue
	print("FORM folder found in main Input folder");
} else if (File.exists(fDir)) {
	// continue
	print("FORM folder not found in main Input folder. Checking main Output folder...");
	print("FORM folder found in main Output folder");
} else if (rbut3a == "Particle shapes" || rbut3a == "Both") {
	print("FORM folder not found in main Input. Opening folder locator...");
	fDir=getDirectory("INPUT FILES CHECK: Select Input folder containing the files to measure Particle shapes");
	print(fDir);
	}
	
if (File.exists(input+File.separator+"SEGMENTED")) {
	sDir = input+File.separator+"SEGMENTED";
	// continue
	print("SEGMENTED folder found in main Input folder");
} else if (File.exists(sDir)) {
	// continue
	print("SEGMENTED folder not found in main Input folder. Checking main Output folder...");
	print("SEGMENTED folder found in main Output folder");
} else if (rbut3a == "Crystallinity - Vesicularity		" || rbut3a == "Both") {
	print("SEGMENTED folder not found in main Input folder. Opening folder locator...");
	sDir=getDirectory("INPUT FILES CHECK: Select Input folder containing the files to measure Crystallinity - Vesicularity");
	print(sDir);
	}
}
//----

close("*");
run("Close All");
run("Clear Results");

if (rbut1 == "No" && rbut2 == "Off") { // If Step 1 and 2 are not running, the following code make up for the missing portions of the code
	setBatchMode(true);
	start = getTime(); //Compute the execution time required to process the files
}  // End of if loop when step 1 and 2 are OFF




if (rbut3a == "Both") {
	print("Start Step 3 - Measurements");
	Formfileschk = getFileList(fDir);
	Formfileschk = Array.sort(Formfileschk);
	print(Formfileschk.length);
	for (ifchk = 0; ifchk < Formfileschk.length ; ifchk++) {
		if(endsWith(Formfileschk[ifchk], "_FORM"+suffix)) {
		} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files");
		} 
	}
	forchk = replace(Formfileschk[0], "_FORM"+suffix, "");
	//print(Formfileschk[0]);
	
	SinSegchk = getFileList(sDir);
	SinSegchk = Array.sort(SinSegchk);
	for (ischk = 0; ischk < SinSegchk.length ; ischk++) {
		if(endsWith(SinSegchk[ischk], "_ftseg"+suffix)) {
		} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files");
		} 
	}
	segchk = replace(SinSegchk[0], "_ftseg"+suffix, "");
	//print(SinSegchk[0]);
		if (forchk != segchk) {
				exit("MEASUREMENT ABORTED"+
				"\n \nIn order to Measure Particle shapes and Cristallinity - Vesicularity"+
				"\ntogether, the two input folders MUST have the same sample files,"+
				"\ni.e., same label and same number of files in the same order.");
				print("Measurement aborted");
		}	
} else if (rbut3a == "Particle shapes") {
	print("Start Step 3 - Measurements: Particle shapes ONLY");
} else if (rbut3a == "Crystallinity - Vesicularity		") {
	print("Start Step 3 - Measurements: Cristallinity - Vesicularity ONLY");
} else {
	print("Step 3 - Measurements: OFF");
}


if (rbut3a != "Off") {
    if (rbut3a == "Particle shapes" || rbut3a == "Both") {
	    Formfiles = getFileList(fDir);
		Formfiles = Array.sort(Formfiles);
	    n = Formfiles.length;
    } else if (rbut3a == "Crystallinity - Vesicularity		") {
	    	SinSeg = getFileList(sDir);
			SinSeg = Array.sort(SinSeg);  
	    	n = SinSeg.length;
	    }

	    //NOTE: The input image for measurement MUST NOT contain any subfolder or other files besides the appropriate ones.   
		//-- Prepare the summary result table by setting the recursive writing of each result row line as new array
		
	    area1 = newArray(n); // Area whole particle (not whole image) from FORM file
	    length1 = newArray(n); // Perimeter of the particle
	    area2 = newArray(n); // Area of the convex hull
	    length2 = newArray(n); // Perimeter of the convex hull
		xstart = newArray(n);
		ystart = newArray(n);
	    ff1 = newArray(n); // Form factor, after Liu et al. 2015; it is called "Circularity" in Fiji/ImageJ, "Angularity" in Avery et al. 2017  	
	    AR1 = newArray(n);
	    round1 = newArray(n);
	    BBX1 = newArray(n);
	    BBY1 = newArray(n);
	    major1 = newArray(n);
	    minor1 = newArray(n);
	    feret1 = newArray(n);
	    minferet1 = newArray(n);
	    solidity1 = newArray(n);
	    area3 = newArray(n); // Area measured for Vesicularity in pixels
	    area4 = newArray(n); // Area measured for Crystallinity in pixels - Repeat this line for each of extra feature generated in Step 1
	    ParID = newArray(n);
//-----------------------------------

		//--- STEP 3 - MEASUREMENTS: PARTICLE SHAPES	
		print("");
		if (rbut3a == "Particle shapes" || rbut3a == "Both") {
		print("Step 3: Processing FORM files to measure shape parameters");
		//--- Measure whole particle area from form file (RGB: 255) - Count 1; 
		run("Clear Results");
		run("Set Measurements...", "area centroid perimeter bounding fit shape feret's redirect=None decimal=3");
		//print(Formfiles.length);
			for (i4a = 0; i4a < Formfiles.length; i4a++) {
				if(endsWith(Formfiles[i4a], suffix)){

					open(fDir+File.separator+Formfiles[i4a]);
					run("Select None");
					run("8-bit"); // force conversion of form file to grayscale
					run("Make Binary"); // force conversion of form file to binary
					run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel"); // force reset scale to use pixels as measurement unit
					print("Processing: " + fDir + File.separator + Formfiles[i4a]);
					titf=getTitle();
					resetThreshold();
					setThreshold(0, 0);
					run("Create Selection"); //Create a selection of the background
					run("Measure");
					area1[i4a] = getResult('Area', 0); // Area of the particle
					length1[i4a] = getResult('Perim.', 0);
					xstart[i4a] = getResult('XStart', 0);
					ystart[i4a] = getResult('YStart', 0);
					ff1[i4a] = getResult('Circ.', 0);
					AR1[i4a] = getResult('Aspect', 0);
					round1[i4a] = getResult('Round', 0);
					BBX1[i4a] = getResult('Width', 0);
					BBY1[i4a] = getResult('Height', 0);
					minor1[i4a] = getResult('Minor', 0);
					major1[i4a] = getResult('Major', 0);
					feret1[i4a] = getResult('Feret', 0);
					minferet1[i4a] = getResult('MinFeret', 0);
					run("Clear Results");
					doWand(xstart[i4a], ystart[i4a]);
					run("Convex Hull");
					run("Measure");
					area2[i4a] = getResult('Area', 0); //Area of the convex hull
					length2[i4a] = getResult('Perim.', 0);
					run("Select None");
					run("Clear Results");
					titID=replace(titf, "_FORM"+suffix, "");
					ParID[i4a] = titID;
					close();
				} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files");
		} 
			}
		} else {
			print("Measurement of Particle Shapes: OFF");
		}
		//----------------------------------------------

		
		//--- STEP 3 - MEASUREMENTS: CRYSTALLINITY - VESICULARITY	
		print("");
		if (rbut3a == "Crystallinity - Vesicularity		" || rbut3a == "Both") {
		print("Step 3: Measuring Cristallinity - Vesicularity");
		//--- For Loop for Crystallinity - vesicularity measurements
		SinSeg = getFileList(sDir);
		SinSeg = Array.sort(SinSeg);	
		for (i4 = 0; i4 < SinSeg.length; i4++) {
			if (endsWith(SinSeg[i4], suffix)) { 
			    print("Processing: " + sDir + File.separator + SinSeg[i4]);
			    //-- Open the file
			    open(sDir+File.separator+SinSeg[i4]);
			    run("Select None");
			    run("8-bit"); // force conversion of form file to grayscale
				run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel"); // force reset scale to use pixels as measurement unit
				ot=getTitle();
					/*--- Exception code in case measurement of particle shapes is off. In this case, particle area is quantified
					 * from the segmented image rather than the form file
					 */
					if (rbut3a == "Crystallinity - Vesicularity		") {
						run("Set Measurements...", "area centroid perimeter bounding fit shape feret's redirect=None decimal=3");
						titID=replace(ot, "_ftseg"+suffix, "");
						ParID[i4] = titID;
						/* The following code allows to compute
						 * the measurement of the internal features 
						 * when particle shapes is off
						 */
						selectWindow(ot);				
						resetThreshold();
						setThreshold(bkg, bkg); 
						run("Create Selection");
						run("Make Inverse");
						run("Measure");
						area1[i4] = getResult('Area', 0); //-- Area of the particle
						run("Select None");
						run("Clear Results");	
					} //--- End of exception			
				run("Clear Results");
										
					//--- Vesicles (RGB: 0) - Count 2 - Block 4 - Repeat this block for each of extra feature generated in Step 1
					if (chbVES == true) {
					selectWindow(ot);				
					resetThreshold();
					setThreshold(gfv, gfv);
					run("Create Selection");
					if (selectionType()!=-1) {
						run("Measure");
						area3[i4] = getResult('Area', 0); //-- Area of the vesicles for the whole image
						} else {
							area3[i4] = 0; //-- When vesicularity is 0%	
						}
					run("Select None");
					run("Clear Results");
					} else {
						area3[i4] = 0; //-- Area of the vesicles for the whole image
					}
					//---------------------------------- End of Block 4
												
					//-- Crystals // (RGB: 200) - Count 3
					if (chbOXX == true || grXLS1 == true || grXLS2 == true || grXLS3 == true) {
					selectWindow(ot);	
					resetThreshold();
					setThreshold(gfc, gfc);
					run("Create Selection");
					if (selectionType()!=-1) {
						run("Measure");
						area4[i4] = getResult('Area', 0); //-- Area of the crystals for the whole image
					} else {
						area4[i4] = 0; //-- When vesicularity is 0%	
					}
					run("Select None");
				    run("Clear Results");
					} else {
						area4[i4] = 0; //-- Area of the crystals for the whole image
					}
				    //---
				    
				    close(ot);	
	//--- End of internal feature measurement

run("Clear Results");
			} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files");
				} 
    	}
	} else {
		print("Measurement of Crystallinity - Vesicularity: OFF");
	}

//-- Create Summary result table for all the particles in the input folder
/*
 * Repeat line 3 and 4 below for each of extra feature generated in Step 1
 */


 
		if (rbut3a != "Off") {
	        for (i5=0; i5<n; i5++) {
	        	setResult("Particle ID", i5, ParID[i5]);
				setResult("Particle Area", i5, area1[i5]);
				setResult("VES Area", i5, area3[i5]); // Line 3 ------ feature 4
				setResult("VES %", i5, (100*area3[i5])/area1[i5]); // Line 4 ----- feature 4
				setResult("XLS Area", i5, area4[i5]); //------ feature 1,2,3
				setResult("XLS %", i5, (100*area4[i5])/area1[i5]); //------ feature 1,2,3
			    setResult("Axial ratio", i5, minor1[i5]/major1[i5]);
			    setResult("Solidity", i5, area1[i5]/area2[i5]);
			    setResult("Convexity", i5, length2[i5]/length1[i5]);
			    setResult("Form factor", i5, ff1[i5]); // Called Circularity in Fiji/ImageJ; Parameter name used here from Liu et al. 2015   		      
			    setResult("Particle Perim.", i5, length1[i5]);
			    setResult("CH Area", i5, area2[i5]);
			    setResult("CH Perim.", i5, length2[i5]);
			    setResult("Concavity Index", i5, sqrt((pow(1-(area1[i5]/area2[i5]),2)+(pow(1-(length2[i5]/length1[i5]),2)))));
			    setResult("Major axis", i5, major1[i5]);
			    setResult("Minor axis", i5, minor1[i5]);
			    setResult("BX width", i5, BBX1[i5]);
			    setResult("BY height", i5, BBY1[i5]);
			    setResult("Feret d", i5, feret1[i5]);
			    setResult("MinFeret d", i5, minferet1[i5]);
			    updateResults();
	    	}

			//--- Define label for Results.csv and Log summaries files
			  Dialog.create("Choose label for \"Results\" and \"Log\" summaries");
			  Dialog.addString("", ParID[0]);
			  Dialog.show();
			  Meslabel = Dialog.getString();
			//---------
	    	
			/*-- Save measurements as excel file with R&W excel plugin, 
			 * which creates a folder in the desktop named
			 * Rename me after writing is done.xlsx
			 */
			 if (rbut3b == "Excel(*)		" || rbut3b == "Both") {
				run("Read and Write Excel");
				print("Summary Excel file to be renamed saved on Desktop");
			 }
			 
			 if (rbut3b == "CSV" || rbut3b == "Both") {
				selectWindow("Results");
				saveAs("Results", output+File.separator+Meslabel+"_Summary.csv");
				print("Summary CSV file saved inside the Output folder");
			 }
			 
		}			
//----

print("End of Step 3");
}

if (rbut1 == "No" && rbut2 == "Off" && rbut3a == "Off") {
	print("ALL STEPS ARE OFF");
}

//-- Print running time for the whole process
end = getTime()-start; //calculate processing time
if (end<60000) {
	print("Total processing time:", ((end/1000) % 60)+" seconds");
	} 	
 else {
	print("Total processing time:", ((end/(1000*60)) % 60)+" minutes"); 
}

//--- Exception: Define label for Log summary file if Step 3a Measurement is OFF
if (rbut3a == "Off") {
	Dialog.create("Choose label for \"Results\" and \"Log\" summaries");
	Dialog.addString("Label:", SummaLab);
	Dialog.show();
	Meslabel = Dialog.getString();
}
//---------

//--- Save Log file in the main Output folder
selectWindow("Log");
saveAs("Text", output+File.separator+Meslabel+"_Log.txt");
print("Summary Log file saved inside the Output folder");
//--- End save Log

//-- Clean desktop from processing windows
close("*");
run("Close All");

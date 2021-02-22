     
/* PArticle Shapes and Textures Analyzer (PASTA) v3.7 (February 22, 2021)
 * in: The PArticle Shapes and Textures Analyzer (PASTA) project
 * Authors: Pier Paolo Comida (a), Pierre-Simon Ross (b)
 * (a) piercomida@gmail.com, (b) rossps@ete.inrs.ca
 * Link for download: https://doi.org/10.5281/zenodo.3336335
 * Institut national de la recherche scientifique, 490 rue de la Couronne, Québec (Qc), G1K 9A9, Canada
 * 
 * License: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 *
 * OVERVIEW
 * This script has been developed on (Fiji© Is Just) ImageJ, and it has not been tested with the standard version of ImageJ©.
 * 
 * Version note: This version of the script has been tested with the release 1.53c of Fiji (ImageJ). Its use is therefore not guaranteed with later versions of the software.
 * 
 * The macro processes one or multiple input image files at the same time, with the latter having the same background color (inter-particle area).
 * 
 * In order to work correctly, the script needs the plugin "Read and Write Excel". The plugin can be installed from the Fiji menu Help->Update.
 * 
 * DESCRIPTION
 * 
 * This script allows to measure shape parameters, cristallinity and vesicularity on 2-D cross sections of juvenile particles embedded in polished grain mounts and scanned using BSE-SEM.
 * The full processing procedure consists of three steps:
 * Step 1 - Extract single particles as separate images from input multi-particle images. Input images must have a homogeneously colored inter-particle area.
 * Step 2 - Single particle images are used to generate a binary form image for measuring shape parameters, and a greyscale segmented image to measure bulk 2-D vesicularity and 2-D crystallinity,
 * Step 3 takes the binary form and segmented greyscale image files to measure shape and textural parameters. 
 * The output of the script is:
 * - Drawing of the input multi-particle image, useful to locate the particle on the sample
 * - Single particle images with colored background 
 * - Binary form file of each particle
 * - greyscale segmented image of each particle
 * - A summary of the measurements, saved as excel and/or .csv files
 * - A log file containing full details on the operations done by the script.
 * 
 * NOTES: 
 * 1) For measuring the shape parameters, the script integrates and extends the functionality of the macro code 1-s2.0-S221424281500039X-mmc2.txt, 
 * published by Liu, E.J., et al (2015). Optimising Shape Analysis to quantify volcanic ash morphology. GeoResJ, https://doi.org/10.1016/j.grj.2015.09.001
 *
 * 
 * 3) Circularity is calculated in ImageJ as 4pi(area/perimeter^2)
 * A circularity value of 1.0 indicates a perfect circle. As the value approaches 0.0, it indicates an increasingly elongated polygon.
  */

setOption("BlackBackground",true);
roiManager("reset");
run("Clear Results");
close("*");
run("Close All");
print("\\Clear");

#@ File (label = "Input images*", style = "directory") input
#@ File (label = "Main Output folder", style = "directory") output
#@ String (label = "Image file suffix", value = ".tif") suffix
#@ String (visibility=MESSAGE, value="<html> <b> (*) Input type formats accepted, in order of preference: </b> <ol> <li> <b> <em> RGB Color </em> - DEFAULT for full image processing </b> </li> <li>  <em>  8-bit </em> - ONLY for particle isolation and/or new shape files generation of CUSTOM binary images </li> </ol> </html>", required=false) Optionalnote

print("PASTA v3.7"); // Version label

//--- Time and date
 MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
 DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
 	TimeString ="Date: "+DayNames[dayOfWeek]+" ";
 if (dayOfMonth<10) {TimeString = TimeString+"0";}
 	TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
 if (hour<10) {TimeString = TimeString+"0";}
 	TimeString = TimeString+hour+":";
 if (minute<10) {TimeString = TimeString+"0";}
 	TimeString = TimeString+minute+":";
 if (second<10) {TimeString = TimeString+"0";}
 	TimeString = TimeString+second;
 print(TimeString);
 //---

//--- INITIAL DIALOG BOX FOR PROCESSING SETTINGS

	Dialog.create("Script processing settings");
	//--- Create initial dialog box
	Dialog.setInsets(0, 0, 0);
	// First part allows to select the steps to be run
  	Dialog.setInsets(0, 0, -10);
	Dialog.addMessage("SELECT THE TASKS TO BE EXECUTED");
  	items1 = newArray("Yes		", "No");
  	Dialog.addRadioButtonGroup("1. Isolate single particles (Select \"No\" "+
  	"if single particle images are available)", items1, 1, 2, "Yes		");
	Dialog.setInsets(0, 40, 0);
  	Dialog.addNumber("Minimum pixel number for particle isolation", 100);
  	
	Dialog.setInsets(0, 12, 0);
	items2 = newArray("Particle shapes", "Crystallinity - Vesicularity		", "Both", "Off");
  	Dialog.addRadioButtonGroup("2. Image processing", items2, 1, 4, "Both");
  		
 	Dialog.setInsets(0, 12, 0);
	items3a = newArray("Particle shapes", "Crystallinity - Vesicularity		", "Both", "Off");
  	Dialog.addRadioButtonGroup("3a. Measurements", items3a, 1, 4, "Both");
  	
	Dialog.setInsets(0, 12, -5);
	items3b = newArray("Excel(*)		", "CSV", "Both", "Off");
  	Dialog.addRadioButtonGroup("3b. Save results spreadsheet (Requires 3a to be active)", items3b, 1, 4, "Both");
  	Dialog.setInsets(0, 40, -15);
  	Dialog.addMessage("(*) Saved on Desktop as: Rename me after writing is done.xlsx");
 	
 	Dialog.setInsets(0, 0, -5);	
	Dialog.addMessage("_________________________________________________________________________________________________________________");

	Dialog.setInsets(0, 0, 0);
	Dialog.addMessage("GREYSCALE VALUES FOR OUTPUT SEGMENTED IMAGES");
	Dialog.setInsets(-5, 0, 0);
	Dialog.addMessage("(NOTE: if using only the measurement function with custom images, the following values MUST match those of the processed images)");
	Dialog.addNumber("Vesicles:", 0); // Set the greyscale intensity for the vesicles
	Dialog.addToSameRow();
	Dialog.addNumber("All crystals (includes oxides):", 200); // Set the greyscale intensity for the crystals
	Dialog.addToSameRow();
	Dialog.addNumber("Groundmass:", 120); // Set the greyscale intensity for the groundmass
	//Dialog.addToSameRow();
	Dialog.addNumber("Background:", 255); // Set the greyscale intensity for the background/outside particle
 	Dialog.setInsets(0, 250, 0);	
	Dialog.addMessage("(Example of greyscale values: 0 = Black ; 120 = Dark grey ; 200 = Light grey ; 255 =  White)");
	
	//---  Show the dialog box, creating the following variables for each entry
		Dialog.show();
	
	// PART 1
		rbut1 = Dialog.getRadioButton(); // Step 1 - Isolate particles
		rbut1n = Dialog.getNumber(); // Step 1 - Minimum pixel number for particle isolation
		rbut2 = Dialog.getRadioButton(); // Step 2 - Image processing
		rbut3a = Dialog.getRadioButton(); // Step 3a - Measurements
		rbut3b = Dialog.getRadioButton(); // Step 3b - Save results spreadsheet

	// PART 3
		gfv = Dialog.getNumber(); // Greyscale value segmented image for vesicles
		gfc = Dialog.getNumber(); // Greyscale value segmented image for crystals
		gfo = Dialog.getNumber(); // Greyscale value segmented image for groundmass
		bkg = Dialog.getNumber(); // Greyscale value segmented image for background

//--- END OF INITIAL DIALOG BOX
	
// INITIAL SETTINGS PRINT
print("");
print("INITIAL SETTINGS");
print("Step 1 - Isolate particles: ", rbut1);
if (rbut2 == "Particle shapes"){
	print("Step 2 - Image processing: "," ONLY ",rbut2);
} else if (rbut2 == "Crystallinity - Vesicularity		"){
	print("Step 2 - Image processing: "," ONLY ", rbut2);
} else {
	print("Step 2 - Image processing: ", rbut2);
}
print("Step 3a - Measurements: ", rbut3a);

if (rbut1 == "No" && rbut2 == "Off" && rbut3a == "Off") {
	exit("SCRIPT ABORTED: No steps active");
}

if (rbut3a != "Off") {
	if (rbut3b == "Both") {
		print("Step 3b - Save results as: ", rbut3b, " Excel and .csv files");
	} else {
		print("Step 3b - Save results as: ", rbut3b, " file");
	}	
}
print("");			
print("Greyscale values for segmented images:");
print("Vesicles: ", gfv);
print("Crystals: ", gfc);
print("Groundmass: ", gfo);
print("Background (Area outside the particle): ", bkg);
print("");

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
		 * i.e., a greyscale version of a single particle image with the filtered internal phases
		 * homogeneized to have a single, different greyscale intensity
		 */
			sDir = output+File.separator+"SEGMENTED";
		if (rbut2 == "Crystallinity - Vesicularity		" || rbut2 == "Both") {
			if (File.exists(sDir)) {
				// do nothing
			} else {
				File.makeDirectory(sDir);
			}
		}

		//--- Create folder for Segmentation temp Log files if single segmentation mode is chosen
		
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
	//Array.print(Imagefiles);
	if (Imagefiles.length == 0) { // Check if input folder is empty: if yes, it aborts the script and displays an error message
		exit("SCRIPT ABORTED: Input folder is empty");
	}
	
	print("Number of files in the Input folder:", Imagefiles.length);
	for (i = 0; i < Imagefiles.length; i++) {
		if(endsWith(Imagefiles[i], suffix) && File.isDirectory(Imagefiles[i]) == false){
		print("");
		print("Isolating single particles : " + input + File.separator + Imagefiles[i]);
	
	    //-- Open the file
		open(input+File.separator+Imagefiles[i]);
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		run("Select None");
	    title = getTitle();
	    itype = bitDepth(); // get the type format of the image: 24 = RGB color; 8 = 8-bit
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
					if (selectionType() != -1 && checkRGB == "No") {
						run("Select None"); // reset selection type if user forgets to use the point tool 
					}				
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

			//--- Start Thresholding with check if image is in a RGB or greyscale format
			if (itype == 8) {
				//--- Image is in greyscale format, run simple threshold
				resetThreshold(); 
				setThreshold(b, b);
				run("Convert to Mask");

				//print("Entered Greyscale thresholding");			
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
			} //--- End of Thresholding
			setThreshold(0, 0);	

					/* the analyzer count the single particles and add them to the ROI manager, 
					 *  excluding those ones touching the edge 
					 */
					run("Analyze Particles...", "size=rbut1n-Infinity show=Outlines exclude add");

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
						if (itype == 8) {
							setForegroundColor(b, b, b);
							setBackgroundColor(b, b, b);
						} else {
							setForegroundColor(r, g, b);
							setBackgroundColor(r, g, b);
						}							
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
							print("Generating RGB single particle file:", orgb);
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
			exit("SCRIPT ABORTED: Wrong suffix for image files or other files/folders are present in the main input folder");
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

//--- STEP 2 - IMAGE PROCESSING	

	if (rbut2 != "Off") {

	print("Start Step 2 - Image processing");

	roiManager("reset");
	run("Clear Results");

	if (rbut1 == "No") { // If particle isolation is not running, the following code make up for the missing portions of the code
			inputEmptChk = getFileList(myDir1); // to check if the RGB singles folder is empty
			if (File.exists(myDir1) && inputEmptChk.length != 0) { // Check if RGB single files folder is present in the output folder
				// continue
			} else if (File.exists(input+File.separator+"RGB_Singles")) { // Check for a "RGB_Singles" folder in the main INPUT folder
				print("RGB_Singles folder in the main output folder is empty. Folder found in the main input folder."); 
				myDir1 = input+File.separator+"RGB_Singles";
				print(myDir1);
			} else { // Otherwise, it takes the INPUT folder as the main location for the files
				print("RGB_Singles folder not found in the main input folder. The files are directly present in the main input folder."); 
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

	for (ia = 0; ia < pickList0.length; ia++) {
		if(endsWith(pickList0[ia], suffix) && File.isDirectory(pickList0[ia]) == false){
		} else { // Abort macro if suffix is not the right one
				exit("SCRIPT ABORTED: Wrong suffix for image files or other files/folders are present in the main input folder");
			} 		
	}
	open(myDir1+File.separator+pickList0[0]);
	SummaLab = pickList0[0];	// Store the name of the first file opened in order to name the log file at the end
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
			}
			x2 = getResult("X", 0);
			y2 = getResult("Y", 0);
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

if (rbut1 == "No") {
	setBatchMode(true); //This line hides the opening of the images during processing
	start = getTime(); //Compute the execution time required to process the files
}

//--- PARTICLE SHAPE PROCESSING
	//--- Start automated Main BATCH loop that process single RGB image files located in the main OUTPUT folder
	// In this portion, RGB single images are processed in sequence to generate the form files
	formLabel = "_FORM";
	
	if (rbut2 == "Particle shapes" || rbut2 == "Both") {
		print("Processing Particle shapes");
		Psingles = getFileList(myDir1);
		Psingles = Array.sort(Psingles);
		print("Number of files in ", myDir1, ":", Psingles.length);
		print(""); // Create a space line in the Log between the two steps
			for (i10 = 0; i10 < Psingles.length; i10++) {
				if(endsWith(Psingles[i10], suffix) && File.isDirectory(Psingles[i10]) == false){	
				//print(myDir1 + File.separator + Psingles[i10]);
				//-- Open the file
					open(myDir1+File.separator+Psingles[i10]);
					run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
					run("Select None");
					orgb=getTitle();
					oRGbWidth = getWidth(); // Get Width of the opened RGB single for selection check further below
					itype = bitDepth(); // get the type format of the image: 24 = RGB color; 8 = 8-bit
					SummaLab = Psingles[0];
				
				// --- START IMAGE PROCESSING: PARTICLE SHAPES
	
				//--- Create duplicate for form
					run("Duplicate...", "title=FORM");
					dupform=getTitle();			
				//-------
		
				//--- Create FORM and selection
					selectWindow(dupform);
					//--- Start Thresholding with check if image is in a RGB or greyscale format
						if (itype == 8) {
							//--- If image is in greyscale format, run simple threshold
							resetThreshold(); 
							setThreshold(b, b);

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
	
						// Check for correct selection on particle shape		
						run("Create Selection");
						List.setMeasurements;
						WidthCheck = List.getValue("Width");
						if (WidthCheck == oRGbWidth) {
							//print("Selection on outside area. Inverting back on particle shape...");
							run("Make Inverse");
						} else {
							print("Selection on particle. Continue...");
						}
						//--- Generate binary FORM image file 					
						setForegroundColor(0, 0, 0);
						run("Fill", "slice"); // Fill particle form
						run("Make Inverse");
						setForegroundColor(255, 255, 255);
						run("Fill", "slice"); // fill background
						run("Make Inverse");
						run("Make Binary");
						//-------
					
						//--- Save single particle Form binary image
							run("Select None"); // Reset selection of form particle before saving the file
							dupform=replace(orgb, suffix, formLabel+suffix);
							rename(dupform);
							print("Generating binary shape file:", dupform);
							saveAs("TIFF",fDir+File.separator+dupform);
							close();							
						//------
						
				} //--- End of image processing: particle shapes (if loop)
			} //--- End of image processing: particle shapes (for loop)
	} // if loop for processing particle shapes if options are selected

close("*");
run("Close All");
run("Clear Results");

//--- GENERATION OF SEGMENTED PARTICLE IMAGE FOR CRYSTALLINITY - VESICULARITY
segLabel = "_ftseg";
			
	if (rbut2 == "Crystallinity - Vesicularity		" || rbut2 == "Both") {
			
	print("");
	print("----------------------------");
	print("Processing Crystallinity - Vesicularity");

					waitForUser("Image segmentation for 2D crystallinity - 2D vesicularity - Intro", "For each internal feature (vesicles, oxides, crystals, etc.) of each image,"+
					" you have to select the threshold values."+
					"\n \nThreshold selection works through two dialog boxes, in the following order:"+
					"\n \n1) In the \"Image, feature & threshold values selector\" menu, choose the image number to be thresholded"+
					"\n    or simply click \"OK\" at the bottom of the box to start from the first image in the folder."+
					"\n2) Now follow the directions in the \"Instructions\" dialog box to pick"+
					"\n    the threshold intensity values for a desired feature, then press Ok when done."+
					"\n3) Back in the \"Image, feature & threshold values selector\" box, enter the threshold values"+ 
					"\n    and exclude any feature to be extracted if necessary. With the \"Auto scroll\" checkbox unticked,"+ 
					"\n    go back to the same image by simply clicking \"OK\", in order to threshold another feature."+
					"\n    Once all features for one image are acquired, tick the \"Check to exit\" box"+
					"\n    to segment the current image and then pass to the next."+
					"\n    If values for a specific image can be applied to the entire stack of images,"+
					"\n    check the \"Batch segmentation\" box to automatically segment the rest of the images in the folder."+   
					"\n \nPress Ok to start.");

						//--- Default entry values for "Dialog Box 2: Image segmentation"

							chbVES = true; // Vesicles Checkbox
							LVES = "VES";    // Vesicles Label
							VESpse = 4;   // Vesicles min. pixel size extraction						
					
							chbOXX = true; // Oxides Checkbox
							LOXX = "oxides";    // Oxides Label
							OXXpse = 4;   // Oxides min. pixel size extraction
												
							grXLS1 = true; // Grey Crystals 1 checkbox
							LXLS1 = "darkXLS"; // Grey Crystals 1 label
							XLS1pse = 20; // Grey Crystals 1 min pixel size extraction
											
							grXLS2 = false; // Grey Crystals 2 checkbox
							LXLS2 = "medXLS"; // Grey Crystals 2 label
							XLS2pse = 20; // Grey Crystals 2 min pixel size extraction
											
							grXLS3 = false; // Grey Crystals 3 checkbox
							LXLS3 = "lightXLS"; // Grey Crystals 3 label
							XLS3pse = 20; // Grey Crystals 3 min pixel size extraction
							
							ftVESmin = 0; // Default min vesicles threshold value
							ftVESmax = 5; // Default max vesicles threshold value
							ftOXXmin = 250; // Default min oxides threshold value
							ftOXXmax = 255; // Default max oxides threshold value
							ftgrXLS1min = 60; // Default min XLS1 threshold value
							ftgrXLS1max = 118; // Default max XLS1 threshold value
							ftgrXLS2min = 72; // Default min XLS2 threshold value
							ftgrXLS2max = 160; // Default max XLS2 threshold value
							ftgrXLS3min = 85; // Default min XLS3 threshold value
							ftgrXLS3max = 200; // Default max XLS3 threshold value
						


						//--- Number of files in the RGB Singles folder, as reference
						pickList = getFileList(myDir1);
						pickList = Array.sort(pickList);
						pickL = pickList.length;
						print ("Total number of files in RGB_Singles folder: ", pickL);
						
						//-------------

						//--- Number of files in the SEGMENTED folder
						sDirList = getFileList(sDir);
						sDirList = Array.sort(sDirList);
						sDirL = sDirList.length;
						print("Total number of files in SEGMENTED folder: ", sDirL);
						//-----------------	

						MissSegArr = newArray();
						SavPosRemArr = newArray();						
						if (sDirL == pickL) {
							print("NOTE: Image segmentation has been skipped as all segmented images are present."+
							"If you need to re-segment a specific image, please delete the file in the SEGMENTED folder and re-run the script.");
						} else if(sDirL != pickL && sDirL > 0) {
							// PRINT LIST OF MISSING FILES
							print("Missing segmented files:");
							//redjcountMisF = 0; // Adjust recount of segmented files for checking
							for (misSegfi = 0; misSegfi < pickL; misSegfi++) {
								CompPickListFile = replace(pickList[misSegfi], suffix, segLabel+suffix);
								//print(misSegfi);
								for (inCountMisf = 0; inCountMisf < sDirL; inCountMisf++) {
									//print(inCountMisf);
									if (CompPickListFile == sDirList[inCountMisf]) {
										break;
									} else if (CompPickListFile != sDirList[inCountMisf] && inCountMisf == sDirL-1) {
										SavPosRemFiles = misSegfi+1;
										print(CompPickListFile, " - At position: ",misSegfi+1);
										//redjcountMisF = redjcountMisF+1;
										MissSegArr = Array.concat(MissSegArr, CompPickListFile);
										RemLabels = MissSegArr;
										SavPosRemArr = Array.concat(SavPosRemArr,SavPosRemFiles);
										RemIndexes = SavPosRemArr;
									}
								}
								
							}
						}
						//Array.print(MissSegArr);
						MissSegArrLength = MissSegArr.length;
						if (MissSegArrLength > 0) {
							ForceExitWhileLoop = MissSegArrLength;
						} else if (MissSegArrLength == 0) {
							ForceExitWhileLoop = pickL;
						}
						//print(MissSegArrLength);	
						n0 = 0;
						//numb2 = 0;
						isgCheck = 0;
						trsel = false; // Variable to control exit check box to move to next particle image
						rbut2a = false; // Variable to control batch segmentation check box
						advscrol = false; // Variable to control slider scroll; If true, the next image is opened after each cycle
						manuScroll = 0;
						atscroll = false; // Default check of inactive autoscroll

			
			while (sDirL < pickL) { // This loop allows script to exit once all segmented files have been created
				
				//--- Image segmentation dialog box For loop

				for (isg = 0; isg < pickList.length; isg++) {
					if(endsWith(pickList[isg], suffix) && File.isDirectory(pickList[isg]) == false){
						
						if (rbut2a == false) { // Start loop for single segmentation
							if (isg != isgCheck) {	
								trsel = false;
							}
							sameImgOp = -100; // Default value to open selected image
							snglImgPro = 0; // Allows the opening of the selected image in the folder
							while (trsel == false) { // Stay on image thresholding until the exit check is ticked
								
								/*This part concerns the extraction of the internal features,
								 * which will enabled only if Step 1 is active
								 */
									if (snglImgPro == 0) {
										setBatchMode(false); // This command is needed to force the image to show
										open(myDir1+File.separator+pickList[isg]);
										if (advscrol == true) {
											atscroll = true; // check if autoscroll is active and keep it until changes
										} else if (advscrol == false) { // if autoscroll is unticked, autoscroll check goes back to default
											atscroll = false;
										}
										sameImgOp = isg;
										curSImg = getTitle();
										snglImgPro = isOpen(curSImg);
										wToSegImg = getWidth()/2;
										hToSegImg = getHeight()/2;
										convPtPx = 1.3281472327365; // px
										sizFontOv = (wToSegImg/4)/convPtPx;
										setFont("Arial", sizFontOv, "Bold");
										setColor("Yellow");
										setJustification("center");
										Overlay.drawString("IMAGE PREVIEW", wToSegImg,hToSegImg); // position is x, y
										Overlay.show();				
									} else if (snglImgPro == 1) {
										Overlay.drawString("IMAGE PREVIEW", wToSegImg,hToSegImg); // position is x, y
										Overlay.show();	
									}
								
									//--- Dialog Box 1: Image, features & values selector
									Dialog.create("Image, features & values selector");
									Dialog.setInsets(0, 10, 0);
									Dialog.addMessage("(1) Image selector (Enter a number or use the scroll bar)");
									Dialog.addSlider("", n0+1, pickL, isg+1);
									Dialog.addToSameRow();
									Dialog.addCheckbox("Auto scroll", advscrol);
									Dialog.setInsets(0, 196, 0);
									Dialog.addMessage("Min: "+n0+1+"                    Max: "+pickL);
								 	Dialog.setInsets(0, 10, 0);	
									Dialog.addMessage("______________________________________________________________________________");
									
									//--- Features and minimum size extraction
										//Dialog.setInsets(top, left, bottom) Reminder
										//--- Vesicles
										Dialog.setInsets(0, 10, 0);
										Dialog.addMessage("(2) Select features, label and minimum size extraction");
										Dialog.setInsets(0, 12, 0);
										Dialog.addCheckbox("Vesicles", chbVES);
										Dialog.addToSameRow();
										Dialog.addString("Label (one word):", LVES, 10);
										Dialog.setInsets(0, 30, 0);
										Dialog.addNumber("Minimum pixel size extraction:", VESpse);
										//------
			
										//--- Oxides
										Dialog.setInsets(5, 12, 0);
										Dialog.addCheckbox("Oxides", chbOXX);
										Dialog.addToSameRow();
										Dialog.addString("Label (one word):", LOXX, 10);
										Dialog.setInsets(0, 30, 0);
										Dialog.addNumber("Minimum pixel size extraction:", OXXpse);
										//------
			
										//--- Grey Crystals 1
										Dialog.setInsets(5, 12, 0);
										Dialog.addCheckbox("Grey crystals 1", grXLS1);
										Dialog.addToSameRow();
										Dialog.addString("Label (one word):", LXLS1, 10);
										Dialog.setInsets(0, 30, 0);
										Dialog.addNumber("Minimum pixel size extraction:", XLS1pse);	
										//------
																														
										//--- Grey Crystals 2
										Dialog.setInsets(5, 12, 0);
										Dialog.addCheckbox("Grey crystals 2", grXLS2);
										Dialog.addToSameRow();
										Dialog.addString("Label (one word):", LXLS2, 10);
										Dialog.setInsets(0, 30, 0);
										Dialog.addNumber("Minimum pixel size extraction:", XLS2pse);
										//------
			
										//--- Grey Crystals 3
										Dialog.setInsets(5, 12, 0);
										Dialog.addCheckbox("Grey crystals 3", grXLS3);
										Dialog.addToSameRow();
										Dialog.addString("Label (one word):", LXLS3, 10);
										Dialog.setInsets(0, 30, 0);
										Dialog.addNumber("Minimum pixel size extraction:", XLS3pse);													
										//------
									//------------------------
		
										Dialog.setInsets(0, 10, 0);	
										Dialog.addMessage("______________________________________________________________________________");
										
									//--- Insert threshold values	
										Dialog.setInsets(0, 12, 0);
										Dialog.addMessage("(3) Insert Threshold values");
										
										//--- Vesicles
										Dialog.setInsets(0, 12, 0);
										Dialog.addNumber("Vesicles ---> Min:", ftVESmin);
										Dialog.addToSameRow();	
										Dialog.addNumber("Max:", ftVESmax);
										//------
		
										//--- Oxides
										Dialog.setInsets(5, 12, 0);
										Dialog.addNumber("Oxides ---> Min:", ftOXXmin);
										Dialog.addToSameRow();			
										Dialog.addNumber("Max:", ftOXXmax);
										//------
		
										//--- Grey Crystals 1
										Dialog.setInsets(5, 12, 0);
										Dialog.addNumber("Grey Crystals 1 ---> Min:", ftgrXLS1min); 
										Dialog.addToSameRow();			
										Dialog.addNumber("Max:", ftgrXLS1max);
										//------
										
										//--- Grey Crystals 2
										Dialog.setInsets(5, 12, 0);
										Dialog.addNumber("Grey Crystals 2 ---> Min:", ftgrXLS2min); 
										Dialog.addToSameRow();			
										Dialog.addNumber("Max:", ftgrXLS2max);
										//------
										
										//--- Grey Crystals 3
										Dialog.setInsets(5, 12, 0);
										Dialog.addNumber("Grey Crystals 3 ---> Min:", ftgrXLS3min);		
										Dialog.addToSameRow();											
										Dialog.addNumber("Max:", ftgrXLS3max); 	
										//------
									//------------------------------------
									
								 	Dialog.setInsets(0, 10, 0);	
									Dialog.addMessage("_______________________________________________________________________________");
									Dialog.setInsets(10, 12, 0);
									Dialog.addCheckbox("Check to exit.", false);
									Dialog.addToSameRow();
									Dialog.addCheckbox("Batch segmentation", false);
									
									
									//-//
									
									Dialog.show(); // Show Dialog box 1
									
									isg = Dialog.getNumber(); // virtual number of the image from the slider (the first image in the folder is 1)
									isg = isg-1; // actual number of the image (the first image in the folder is 0)
									advscrol = Dialog.getCheckbox(); // Get the value of the auto scroll checkbox
		
									//--- Get - Features and minimum size extraction 
									chbVES = Dialog.getCheckbox(); // Vesicles Checkbox
									LVES = Dialog.getString();    // Vesicles Label
									VESpse = Dialog.getNumber();   // Vesicles min. pixel size extraction						
							
									chbOXX = Dialog.getCheckbox(); // Oxides Checkbox
									LOXX = Dialog.getString();    // Oxides Label
									OXXpse = Dialog.getNumber();   // Oxides min. pixel size extraction
		
															
									grXLS1 = Dialog.getCheckbox(); // Grey Crystals 1 checkbox
									LXLS1 = Dialog.getString(); // Grey Crystals 1 label
									XLS1pse = Dialog.getNumber(); // Grey Crystals 1 min pixel size extraction
													
									grXLS2 = Dialog.getCheckbox(); // Grey Crystals 2 checkbox
									LXLS2 = Dialog.getString(); // Grey Crystals 2 label
									XLS2pse = Dialog.getNumber(); // Grey Crystals 2 min pixel size extraction
													
									grXLS3 = Dialog.getCheckbox(); // Grey Crystals 3 checkbox
									LXLS3 = Dialog.getString(); // Grey Crystals 3 label
									XLS3pse = Dialog.getNumber(); // Grey Crystals 3 min pixel size extraction
		
									//--- Get - Insert threshold values	
									ftVESmin = Dialog.getNumber(); 
									ftVESmax = Dialog.getNumber();
		
									ftOXXmin = Dialog.getNumber(); 
									ftOXXmax = Dialog.getNumber();
		
									ftgrXLS1min = Dialog.getNumber(); 
									ftgrXLS1max = Dialog.getNumber();
		
									ftgrXLS2min = Dialog.getNumber(); 
									ftgrXLS2max = Dialog.getNumber();
		
									ftgrXLS3min = Dialog.getNumber();
									ftgrXLS3max = Dialog.getNumber();
									
									trsel = Dialog.getCheckbox(); // Exit check to process current particle and then move to the next
									rbut2a = Dialog.getCheckbox(); // Process rest of images in batch processing, using last acquired threshold values
								
								Overlay.remove; // remove the "image preview" label from the current image when thresholding
								
								if (rbut2a == true) { // If the user wants to process files in batch segmentation, but forget to tick the "check to exit" button, this statement automatically "tick" it in order to carry on.
									trsel = true;
								}

								if (advscrol == true && trsel == false) { // this part let the slider to advance of one
										isg = isg+1;
									} 
								if (trsel == false) { // Is needed to avoid the code reopening another image
									if (sameImgOp == isg || atscroll == true) {
									// Display tabs and directions to threshold the features
									run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
									run("Select None");
									run("Color Threshold...");
									setTool("zoom");
										if (atscroll == true && isg > pickL-1 && isg > sDirL) {
											advscrol = false;
											isg = isg-1;
											print("Warning: Image auto scroll has been deactivated as end image range has been reached.");
										}
									//--- Dialog Box 2 - Image segmentation: Interactive message WaitForUser, that allows to operate on the image feature to be thresholded		
									waitForUser("Threshold selection - Instructions", "Particle ID: "+pickList[isg]+
									"\n \nTo pick intensity values:"+
									"\n   1) Change the \"Color space\" mode to \"RGB\" in the Color Threshold panel"+
									"\n   2) Zoom on a typical feature"+
									"\n   3) Select your favorite selection tool (First four icons on the left side of the Fiji Toolbar)"+
									"\n   4) Select any representative area of the feature"+
									"\n   5) Click on the \"Sample\" button at the bottom of the Color Threshold panel"+
									"\n   6) Click Ok to return to the Image selector dialog box in order to enter the values"+
									"\n       (Note: Threshold Color Panel will stay open)"+
									"\n   ");
									//----------------------------
									}
									
									if (sameImgOp != isg) { // Open Image with reopening check when scrolling images
										snglImgPro = 0;
										close();
									}
								} // end if statement on reopening
							
							} // End while loop
					
							close();
							//--- Print Initial parameters
								if (rbut2 != "Off") {
									// PART 2
									print("----------------------------");
									print("");
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

							if (rbut2a == true) {
								print("");
								print("BATCH SEGMENTATION activated: processing rest of images in batch processing");
								print("Threshold values acquired up to image " + pickList[isg] + "; Folder path:" + myDir1+File.separator);
							}
										
							//--- Print chosen threshold values

								// Vesicles
									if (chbVES==true) { // Vesicles
										print("Selected Threshold values for "+LVES+": Min: "+ftVESmin+", Max: "+ftVESmax);
									} 	
								
								// Oxides
									if (chbOXX==true) { // Oxides
										print("Selected Threshold values for "+LOXX+": Min: "+ftOXXmin+", Max: "+ftOXXmax);
									}	
								
								// Grey Crystals 1
									if (grXLS1==true) { // Grey Crystals 1	
										print("Selected Threshold values for "+LXLS1+": Min: "+ftgrXLS1min+", Max: "+ftgrXLS1max);
									} 	

								// Grey Crystals 2
									if (grXLS2==true) { // Grey Crystals 2	
										print("Selected Threshold values for "+LXLS2+": Min: "+ftgrXLS2min+", Max: "+ftgrXLS2max);
									}

								// Grey Crystals 3	
									if (grXLS3==true) { // Grey Crystals 3	
										print("Selected Threshold values for "+LXLS3+": Min: "+ftgrXLS3min+", Max: "+ftgrXLS3max);
									}

							//---------------------------

						} // End if loop for single segmentation
										
					setBatchMode("hide"); // All the current images and related processing is hidden, making processing much faster
					// --- START IMAGE PROCESSING: FEATURE EXTRACTION
					
					print("Now processing: " + myDir1 + File.separator + pickList[isg]," ; Count: ", isg+1);
					open(myDir1+File.separator+pickList[isg]);
						
							//--- Crystallinity-vesicularity extraction part of Step 2	
							/*  --- Create duplicates ---
							*  This part creates duplicates of the
							*  filtered image, one for each single feature
							*  Repeat line 1 to 5 below for each one
							*  of the internal features to be extracted
							*/
							selectWindow(pickList[isg]);
							selframeWidth = getWidth();
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
						
							// Grey Crystals 1
							if (grXLS1==true) {
							run("Duplicate...", "title=&LXLS1");
							dupXLS1=getTitle();
							}
						
							// Grey Crystals 2
							if (grXLS2==true) {
							run("Duplicate...", "title=&LXLS2");
							dupXLS2=getTitle();
							}
							
							// Grey Crystals 3						// line 1
							if (grXLS3==true) { 					// line 2
							run("Duplicate...", "title=&LXLS3");    // line 3
							dupXLS3=getTitle(); 					// line 4
							}										// line 5
							
							//print(isOpen(dupVES)); 
							//print(isOpen(dupOXX)); 		
							//print(isOpen(dupXLS1)); 		
							//print(isOpen(dupXLS2)); 
							//print(isOpen(dupXLS3)); 
						
							//waitForUser("check duplicates for extraction");
			
						//--- Start feature Extraction
							/*  
							*   Repeat Block 1 for features that can be thresholded in Greyscale
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
								run("Analyze Particles...", "size=&OXXpse-Infinity circularity=0.09-1.00 show=Masks clear"); // min value for circularity as oxides are usually equant. Used to filter noise 
								run("Invert LUT");
								run("Create Selection");
								// Write save code here in case you desire save this file			
								close(dupOXX); // close duplicate for Oxides
								rename(dupOXX);
							} //--- End Oxides --------------------------------------------------------------------------------End of Block 1	
			
							//--- Extract Grey Crystals 1 
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
									
								close(dupXLS1); // close duplicate for Grey Crystal 1
								rename(dupXLS1);	
							} //--- End Grey crystals 1 extraction 
						
							//--- Extract Grey Crystals 2
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
								close(dupXLS2); // close duplicate for Grey Crystals 2
								rename(dupXLS2);
							} //--- End Grey Crystals 2 extraction
						
							//--- Extract Grey Crystals 3 ---------------------------------------------------------------------- Block 2
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
							} //--- End Grey Crystals 3 extraction ------------------------------------------------- End of Block 2
							
						//--- END FEATURE EXTRACTION
							
						//--- Merge single features to create one single image file with the Greyscale features
						/*
						* Repeat Block 3 for each one of the extra features added above
						*/
		
						//---Set base image with Groundmass
							selectWindow(pickList[isg]);
		
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
	
							// Fill of the base image with the groundmass and outside values defined at the beginning of the code
							setThreshold(0, 0);				
							run("Create Selection");
							List.setMeasurements;	
							WidthCheckSegBase = List.getValue("Width");
							if (WidthCheckSegBase == selframeWidth) { // evaluate if the selection is on the frame, and if yes, inverse it in order to select the particle
								//print("Selection on outside area. Inverting back on feature selection...");
								run("Make Inverse");
							}													
							setForegroundColor(gfo, gfo, gfo);						 
							run("Fill");
							setForegroundColor(gfo, gfo, gfo); // The repetition of setforeground and fill is silly, but ImageJ seems not taking the right greyscaale the first time, for some strange reason
							run("Fill"); // 												
							run("Make Inverse");
							setForegroundColor(bkg, bkg, bkg); // 
							run("Fill");
							run("Select None");
							rename("segbase");
							segbase = getTitle();
							//showMessageWithCancel("","Check segbase");	
						// End Set up base greyscale image
						//--- Vesicles
						if (chbVES==true) {
							selectWindow(dupVES);
							List.setMeasurements;		
							WidthCheckVesSel = List.getValue("Width");
							if (WidthCheckVesSel == selframeWidth) {
								//print("Selection on outside area. Inverting back on feature selection...");
								run("Make Inverse");
							}
							setPasteMode("Transparent-zero");
							run("Make Inverse"); // invert back to the frame to paste the selection correctly
							run("Copy");
							close();
							selectWindow(segbase);
							run("Paste");
							run("Make Inverse"); // invert back on the feature selection to fill with the wanted grayscale intensity
							if (selectionType()!=-1) {
								setForegroundColor(gfv, gfv, gfv);
								run("Fill");
								run("Select None");
								resetThreshold();
							}

						} //--- Vesicles
						//showMessageWithCancel("", "Check vesicle result");

						//--- Oxides
						if (chbOXX==true) {
							selectWindow(dupOXX);
							List.setMeasurements;	
							WidthCheckOxxSel = List.getValue("Width");
							if (WidthCheckOxxSel == selframeWidth) {
								//print("Selection on outside area. Inverting back on feature selection...");
								run("Make Inverse");
							}							
							setPasteMode("Transparent-zero");
							run("Make Inverse"); // invert back to the frame to paste the selection correctly
							run("Copy");
							close();
							selectWindow(segbase);
							run("Paste");
							run("Make Inverse"); // invert back on the feature selection to fill with the wanted grayscale intensity
							if (selectionType()!=-1) {
								setForegroundColor(gfc, gfc, gfc);
								run("Fill");
								run("Select None");
								resetThreshold();								
							}
						} //--- Oxides
						//showMessageWithCancel("", "Check oxides result");

						//--- Grey Crystals 1
						if (grXLS1==true) {
							selectWindow(dupXLS1);
							List.setMeasurements;								
							WidthCheckXLS1Sel = List.getValue("Width");
							if (WidthCheckXLS1Sel == selframeWidth) {
								//print("Selection on outside area. Inverting back on feature selection...");
								run("Make Inverse");
							}							
							setPasteMode("Transparent-zero");
							run("Make Inverse"); // invert back to the frame to paste the selection correctly
							run("Copy");
							close();
							selectWindow(segbase);
							run("Paste");
							run("Make Inverse"); // invert back on the feature selection to fill with the wanted grayscale intensity
							if (selectionType()!=-1) {
								setForegroundColor(gfc, gfc, gfc);
								run("Fill");
								run("Select None");
								resetThreshold();								
							}
						} //--- Grey Crystals 1
						//showMessageWithCancel("", "Check XLS 1 result");

						//--- Grey Crystals 2
						if (grXLS2==true) {
							selectWindow(dupXLS2);
							List.setMeasurements;	
							WidthCheckXLS2Sel = List.getValue("Width");
							if (WidthCheckXLS2Sel == selframeWidth) {
								//print("Selection on outside area. Inverting back on feature selection...");
								run("Make Inverse");
							}							
							setPasteMode("Transparent-zero");
							run("Make Inverse"); // invert back to the frame to paste the selection correctly
							run("Copy");
							close();
							selectWindow(segbase);
							run("Paste");
							run("Make Inverse"); // invert back on the feature selection to fill with the wanted grayscale intensity
							if (selectionType()!=-1) {
								setForegroundColor(gfc, gfc, gfc);
								run("Fill");
								run("Select None");
								resetThreshold();								
							}
						} //--- Grey Crystals 2
			
						//--- Grey Crystals 3  ------------------------------------------ Block 3
						if (grXLS3==true) {
							selectWindow(dupXLS3);
							List.setMeasurements;								
							WidthCheckXLS3Sel = List.getValue("Width");
							if (WidthCheckXLS3Sel == selframeWidth) {
								//print("Selection on outside area. Inverting back on feature selection...");
								run("Make Inverse");
							}							
							setPasteMode("Transparent-zero");
							run("Make Inverse"); // invert back to the frame to paste the selection correctly
							run("Copy");
							close();
							selectWindow(segbase);
							run("Paste");
							run("Make Inverse"); // invert back on the feature selection to fill with the wanted grayscale intensity
							if (selectionType()!=-1) {
								setForegroundColor(gfc, gfc, gfc);
								run("Fill");
								run("Select None");
								resetThreshold();								
							}
						} // -------------------------------------------------------- End of Block 3
						run("Select None");
						resetThreshold;					
						//--- Save segmented false-color greyscale images
						ftseg = replace(pickList[isg], suffix, segLabel+suffix);
						rename(ftseg);
						if (File.exists(sDir+File.separator+ftseg) == false && trsel == true) {
							saveAs("TIFF",sDir+File.separator+ftseg);
							print("Generating segmented grayscale file: ", ftseg);
						} else if (File.exists(sDir+File.separator+ftseg) == false && rbut2a == true) {
							saveAs("TIFF",sDir+File.separator+ftseg);
							print("Generating segmented grayscale file: ", ftseg);							
						} 
						sDirList = getFileList(sDir);
						sDirList = Array.sort(sDirList);
						sDirL = sDirList.length;
						close();			
						//--- Clear results for next particle 
						run("Clear Results");
					
					if (rbut2a == false) { // save temp segmentation Log file for single segmentation
						//--- Create folder for Segmentation temp Log files if single segmentation mode is chosen
						TSLDir = output+File.separator+"Temp_Seg_Log";
							if (File.exists(TSLDir)) {
								// do nothing
							} else {
								File.makeDirectory(TSLDir);
							}
						//--- Save Temp segmentation Log file if macro is aborted
						selectWindow("Log");
						if (File.exists(TSLDir+File.separator+"Temp_Seg_Log"+"-"+dayOfMonth+"-"+month+"-"+year+"-"+hour+".txt")) {
							//--- Count txt files in output folder
							LogNList = getFileList(TSLDir);
							LogNList = Array.sort(LogNList);
							countput = LogNList.length;
							Ntxts = 0;
							for (i = 0; i < countput; i++) {
								if (endsWith(LogNList[i], ".txt")  && File.isDirectory(LogNList[i]) == false) {
									Ntxts = Ntxts + 1;
								} else {
									Ntxts = Ntxts + 0;
								}
							} //-------
							saveAs("Text", TSLDir+File.separator+"Temp_Seg_Log"+"-"+dayOfMonth+"-"+month+"-"+year+"-"+hour+"-"+Ntxts+".txt");
							print("Info data for ", ftseg, " saved at: ", output+File.separator+"Temp_Seg_Log"+"-"+dayOfMonth+"-"+month+"-"+year+"-"+hour+"-"+Ntxts+".txt");
						} else {
							saveAs("Text", TSLDir+File.separator+"Temp_Seg_Log"+"-"+dayOfMonth+"-"+month+"-"+year+"-"+hour+".txt");
							print("Info data for ", ftseg, " saved at: ", output+File.separator+"Temp_Seg_Log"+"-"+dayOfMonth+"-"+month+"-"+year+"-"+hour+".txt");
						}
						//--- End save Log
						
						isgCheck = isg; // isgCheck is the value of isg before going back to the for loop, where is increased of 1

						if(MissSegArrLength >= 0){
							for (iverifsegexist = 0; iverifsegexist < MissSegArrLength; iverifsegexist++) {
								if (ftseg == MissSegArr[iverifsegexist]) {
									ForceExitWhileLoop = ForceExitWhileLoop-1;
									print("");
									print("Remaining image files to segment: ", ForceExitWhileLoop);
									if (ForceExitWhileLoop > 0) {
									RemLabels = Array.deleteValue(RemLabels, MissSegArr[iverifsegexist]);
  									print("Labels:");
  									Array.print(RemLabels);
  									RemIndexes = Array.deleteValue(RemIndexes, SavPosRemArr[iverifsegexist]);
  									print("At position:");
  									Array.print(RemIndexes);
									print("");
									}
								}
								if (ForceExitWhileLoop == 0) {
									break;
								}
							}
							
						}

					} // save temp segmentation Log file for single segmentation			
				} // Main for-if subloop
				if (ForceExitWhileLoop == 0) {
					break;
				}
			} // Main for-if loop

			//--- Number of files in the SEGMENTED folder
			sDirList = getFileList(sDir);
			sDirList = Array.sort(sDirList);
			sDirL = sDirList.length;
			print("Total number of files in SEGMENTED folder: ", sDirL);
			//-----------------	
				if (ForceExitWhileLoop == 0) {
					break;
				}			
		} // End of while loop for image segmentation	

			// End of particle extraction and segmentation for a input image
		} // End main if statement if cristallinity-vesicularity or "both" buttons are selected

close("*");
run("Close All");
run("Clear Results");
			
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
if (rbut3a == "Particle shapes" || rbut3a == "Both" && rbut3a != "Crystallinity - Vesicularity		") {
	if (File.exists(input+File.separator+"FORM")) {
		fDir = input+File.separator+"FORM";
		// continue
		print("FORM folder found in main Input folder");
	} else if (File.exists(fDir)) {
		// continue
		print("FORM folder not found in main Input folder. Checking main Output folder...");
		print("FORM folder found in main Output folder");
	} else if (File.exists(fDir) != 1) {
		print("FORM folder not found in main Input or output folders. Opening folder locator...");
		fDir=getDirectory("FORM FILES CHECK - Select the folder containing the files to measure Particle shapes");
		print(fDir);
		}
	}
if (rbut3a == "Crystallinity - Vesicularity		" || rbut3a == "Both" && rbut3a != "Particle shapes") {	
	if (File.exists(input+File.separator+"SEGMENTED")) {
		sDir = input+File.separator+"SEGMENTED";
		// continue
		print("SEGMENTED folder found in main Input folder");
	} else if (File.exists(sDir)) {
		// continue
		print("SEGMENTED folder not found in main Input folder. Checking main Output folder...");
		print("SEGMENTED folder found in main Output folder");
	} else if (File.exists(sDir) != 1) {
		print("SEGMENTED folder not found in main Input or output folders. Opening folder locator...");
		sDir=getDirectory("SEGMENTED FILES CHECK - Select the folder containing the files to measure Crystallinity - Vesicularity");
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
	// -- Checking for discrepancies between form and segmented files number and format label 
	print("Checking for discrepancies between form and segmented files number and format label \n");
	Formfileschk = getFileList(fDir);
	Formfileschk = Array.sort(Formfileschk);
	SinSegchk = getFileList(sDir);
	SinSegchk = Array.sort(SinSegchk);
	if (Formfileschk.length == SinSegchk.length) { // This part check if the number of form files equals that of segmented files
		// continue
	} else {
		exit("Script aborted. Number of form and segmented images are not equal");
	}
	TotN = Formfileschk.length;
	formLabel = "_FORM";
	segLabel = "_ftseg"; 
	resi = false;
	rechck = false;
	for (ichckf = 0; ichckf < TotN ; ichckf++) {
			if (resi == true && rechck == false) {
				ichckf = 0;
				rechck = true;
			}
			//print(" form: ", Formfileschk[ichckf]);
			//print("ftseg: ", SinSegchk[ichckf]);
			if (Formfileschk[ichckf] == SinSegchk[ichckf]) { 
				/* This part checks if the label of each form file 
				 * is equal to each corresponding segmented file 
				 */ 
				//print("1");
			} else if (endsWith(Formfileschk[ichckf], formLabel+suffix) == endsWith(SinSegchk[ichckf], segLabel+suffix)) { 
				/* This part of checks if the label   
				 * of each form file is equal to each corresponding segmented file, when generated through PASTA 
				 */
				 forchk = replace(Formfileschk[ichckf], formLabel+suffix, "");
				 segchk = replace(SinSegchk[ichckf], segLabel+suffix, "");
					if (forchk != segchk) {
							print("Measurement aborted");
							exit("MEASUREMENT ABORTED"+
							"\n \nIn order to Measure Particle shapes and Cristallinity - Vesicularity together,"+
							"\n the two input folders MUST have the same sample files,"+
							"\ni.e., same label and same number of files in the same order.");		
					} 
					
				//print("2");
			} else { // if the label format does not corresponds to neither of the previous ones, the script asks to enter the actual suffix of the file 
				//print("3");
				//Ask for label
				Dialog.create("Label suffix check for form and segmented image files");
				Dialog.addMessage("The script cannot recognize the label suffix of either the form or the segmented files."+
				"\n Please enter the correct suffix of the filename without the extension,"+
				"\n then press ok to continue.");
				Dialog.addString("Enter the form label", formLabel);
				Dialog.addString("Enter segmented label", segLabel);
				Dialog.show();
				formLabel = Dialog.getString();
				segLabel = Dialog.getString();
				resi = true;
			}
		}
	print("Check completed. No discrepancies found.");	

} else if (rbut3a == "Particle shapes") {
	print("Start Step 3 - Measurements: Particle shapes ONLY \n");
	
	print("Checking for discrepancies in file number and format label \n");
	Formfileschk = getFileList(fDir);
	Formfileschk = Array.sort(Formfileschk);
	TotN = Formfileschk.length;
	formLabel = "_FORM";
	resi = false;
	rechck = false;
	for (ichckf = 0; ichckf < TotN ; ichckf++) {
			if (resi == true && rechck == false) {
				ichckf = 0;
				rechck = true;
			}
			print(" form: ", Formfileschk[ichckf]);

				if (endsWith(Formfileschk[ichckf], formLabel+suffix)) { 
				/* This part checks if the label   
				 * of each form file is the default generated through PASTA 
				 */
				} else { // if the label format does not corresponds, the script asks to enter the actual suffix of the file
				//Ask for label
				Dialog.create("Label suffix check for form files");
				Dialog.addMessage("The script cannot recognize the label suffix of the form files."+
				"\n Please enter the correct suffix of the filename without the extension,"+
				"\n then press ok to continue.");
				Dialog.addString("Enter the form label", "_FORM");
				Dialog.show();
				formLabel = Dialog.getString();
				resi = true;
			}
		}
	print("\nCheck completed. No discrepancies found");
	
} else if (rbut3a == "Crystallinity - Vesicularity		") {
	print("Start Step 3 - Measurements: Cristallinity - Vesicularity ONLY \n");

	
	print("Checking for discrepancies in file number and format label \n");
	SinSegchk = getFileList(sDir);
	SinSegchk = Array.sort(SinSegchk);
	TotN = SinSegchk.length;
	segLabel = "_ftseg";
	resi = false;
	rechck = false;
	for (ichckf = 0; ichckf < TotN ; ichckf++) {
			if (resi == true && rechck == false) {
				ichckf = 0;
				rechck = true;
			}
			print("ftseg: ", SinSegchk[ichckf]);

				if (endsWith(SinSegchk[ichckf], segLabel+suffix)) { 
				/* This part checks if the label   
				 * of each segmented file is the default generated through PASTA 
				 */
				} else { // if the label format does not corresponds, the script asks to enter the actual suffix of the file
				
				//Ask for label
				Dialog.create("Label suffix check for segmented files");
				Dialog.addMessage("The script cannot recognize the label suffix of the segmented files."+
				"\n Please enter the correct suffix of the filename without the extension,"+
				"\n then press ok to continue.");
				Dialog.addString("Enter segmented label", "_ftseg");
				Dialog.show();
				segLabel = Dialog.getString();
				resi = true;
			}
		}
	print("\nCheck completed. No discrepancies found");
	
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
		//xstart = newArray(n);
		//ystart = newArray(n);
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
		print("Step 3: Measuring shape parameters");
		//--- Measure whole particle area from form file (RGB: 255) - Count 1; 
		run("Clear Results");
		run("Set Measurements...", "area centroid perimeter bounding fit shape feret's redirect=None decimal=3");
		//print(Formfiles.length);
			for (i4a = 0; i4a < Formfiles.length; i4a++) {
				if(endsWith(Formfiles[i4a], suffix)  && File.isDirectory(Formfiles[i4a]) == false){

					open(fDir+File.separator+Formfiles[i4a]);
					run("Select None");
					run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel"); // force reset scale to use pixels as measurement unit
					
					// Grayscale format consistency check for binary images
					wdMeas = getWidth(); // get width of the image for comparison
					itypeMeas = bitDepth(); // get the type format of the image: 24 = RGB color; 8 = 8-bit
						if (itypeMeas != 8) {
							run("8-bit"); // force conversion of form file to greyscale
							run("Make Binary"); // force conversion of form file to binary
							setThreshold(0, 0);
							run("Create Selection");
							resetThreshold();
							List.setMeasurements;	
							Wdchkmeas = List.getValue("Width");
							if (Wdchkmeas == wdMeas) { // if the selection is on the outside area, data is inverted
								setForegroundColor(255, 255, 255);
								run("Fill");
								run("Make Inverse"); // invert back on the particle area
								setForegroundColor(0, 0, 0);
								run("Fill");
							} else {
								run("Select None");
							}
							
						} // End consistency check
					print("Processing: " + fDir + File.separator + Formfiles[i4a]);
					titf=getTitle();
					resetThreshold();
					setThreshold(0, 0);
					run("Create Selection"); //Create a selection of the background
					// Consistency check for white background and black particle area
						List.setMeasurements;	
						Wdchkmeas2 = List.getValue("Width");
						if (Wdchkmeas2 == wdMeas) { // if the selection is on the outside area, data is inverted
								setForegroundColor(255, 255, 255);
								run("Fill");
								run("Make Inverse"); // invert back on the particle area
								setForegroundColor(0, 0, 0);
								run("Fill");
						} // End consistency check
					//waitForUser("", "before measuring particle parameters");	Check point for measurement					
					run("Measure");
					area1[i4a] = getResult('Area', 0); // Area of the particle
					length1[i4a] = getResult('Perim.', 0);
					//xstart[i4a] = getResult('XStart', 0);
					//ystart[i4a] = getResult('YStart', 0);
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
					//doWand(xstart[i4a], ystart[i4a]);
					//waitForUser("", "after do wand of convex hull"); Check point for measurement			
					run("Convex Hull");
					//waitForUser("", "after running convex hull, before measuring its area and perimeter");	Check point for measurement				
					run("Measure");
					area2[i4a] = getResult('Area', 0); //Area of the convex hull
					length2[i4a] = getResult('Perim.', 0);
					run("Select None");
					run("Clear Results");
					titID=replace(titf, formLabel+suffix, "");
					ParID[i4a] = titID;
					close();
				} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files or other files/folders are present in the main input folder");
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
			if (endsWith(SinSeg[i4], suffix)  && File.isDirectory(SinSeg[i4]) == false) { 
			    print("Processing: " + sDir + File.separator + SinSeg[i4]);
			    //-- Open the file
			    open(sDir+File.separator+SinSeg[i4]);
			    run("Select None");
				wdMeasXLVS = getWidth(); // get width of the image for comparison
				run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel"); // force reset scale to use pixels as measurement unit							    
			    run("8-bit"); // force conversion of form file to greyscale
				ot=getTitle();
					/*--- Exception code in case measurement of particle shapes is off. In this case, particle area is quantified
					 * from the segmented image rather than the form file
					 */
					if (rbut3a == "Crystallinity - Vesicularity		") {
						run("Set Measurements...", "area centroid perimeter bounding fit shape feret's redirect=None decimal=3");
						titID=replace(ot, segLabel+suffix, "");
						ParID[i4] = titID;
						/* The following code allows to compute
						 * the measurement of the internal features 
						 * when particle shapes is off
						 */
						selectWindow(ot);				
						resetThreshold();
						setThreshold(bkg, bkg); 
						run("Create Selection");
						// Consistency check for measuring particle area when only  Crystallinity - vesicularity step is on
							List.setMeasurements;	
							WdchkmeasXLVS = List.getValue("Width");
							if (WdchkmeasXLVS != wdMeasXLVS) { // if the width of the selection is different than the frame, it means that the background color was not does not found on the frame, and the script aborts
								exit("SCRIPT ABORTED: The frame does not seem to have the defined background greyscale intensity."+ 
								"\n Please make sure you entered the right greyscale output values for your custom segmented images");
							} // End consistency check						
						run("Make Inverse");
						run("Measure");
						area1[i4] = getResult('Area', 0); //-- Area of the particle
						run("Select None");
						run("Clear Results");	
					} //--- End of exception			
				run("Clear Results");
										
					//--- Vesicles (RGB: 0) - Count 2 - Block 4 - Repeat this block for each of extra feature generated in Step 1
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
					//---------------------------------- End of Block 4
												
					//-- Crystals // (RGB: 200) - Count 3
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
				    //---
				    
				    close(ot);	
	//--- End of internal feature measurement

run("Clear Results");
			} else { // Abort macro if suffix is not the right one
			exit("SCRIPT ABORTED: Wrong suffix for image files or other files/folders are present in the main input folder");
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

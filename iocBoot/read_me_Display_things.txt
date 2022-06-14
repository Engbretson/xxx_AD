Ok, so the start_medm and start_caqtdm are an attempt to parse the display paths from the envPaths file so that  if  somewhere where to make AD aware XXX type deployments, the display screens would update with the shared libraries.

BUT still have to change prefix, know if you are using caqtdm or medm, and if you have a GenICam camera, the string so that it can correct find all the related displays.

start_display is an attempt to do this all in a single file and you just pass in the paramters that you need,  so something like

start_display.sh MEDM xxx: ADAravis PGR-CM3-U3-28S4C
start_display.sh CAQTDM xxx: ADAravis PGR-CM3-U3-28S4C
start_display.sh CAQTDM xxx: simDetector

so which display GUI,
the Pv prefix
what the starting screen is
ADAravis,pixirad,pointGrey,prosilica,pixirad,ADSpinnaker,simDetector,URLDriver,ADVimba,mar345,pilatusDetector,eigerDetector
and if it has extended feature screens and what the pattern is.

so the softioc/commands start_caqtdm and start_medm would get a new line such as 
${IOC_STARTUP_DIR}/start_display.sh MEDM xxx: simDetector something

which is done at setup, and then hopefully, never again.


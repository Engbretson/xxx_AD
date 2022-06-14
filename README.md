# xxx
APS BCDA synApps module: xxx

XXX is a template to use when creating an EPICS IOC that provides beam line support.
It uses the various modules that comprise synApps and other support.

For more information, see
   http://www.aps.anl.gov/bcda/synApps

converted from APS SVN repository: Fri Nov 20 18:04:37 CST 2015

Regarding the license of tagged versions prior to synApps 4-5,
refer to http://www.aps.anl.gov/bcda/synApps/license.php

[Report an issue with XXX](https://github.com/epics-modules/xxx/issues/new?title=%20ISSUE%20NAME%20HERE&body=**Describe%20the%20issue**%0A%0A**Steps%20to%20reproduce**%0A1.%20Step%20one%0A2.%20Step%20two%0A3.%20Step%20three%0A%0A**Expected%20behaivour**%0A%0A**Actual%20behaviour**%0A%0A**Build%20Environment**%0AArchitecture:%0AEpics%20Base%20Version:%0ADependent%20Module%20Versions:&labels=bug)  
[Request a feature](https://github.com/epics-modules/xxx/issues/new?title=%20FEATURE%20SHORT%20DESCRIPTION&body=**Feature%20Long%20Description**%0A%0A**Why%20should%20this%20be%20added?**%0A&labels=enhancement)

* [HTML documentation](https://github.com/epics-modules/xxx/blob/master/documentation/README.md)

**********************************************************************************************************************
This is a modification to also build single Area Detector support modules within xxx as well and multiple AD binaries.
**********************************************************************************************************************

So one can create a "Universal Area Detector binary, which currently include by default 


# Simple ones that always work

ADURL=$(AREA_DETECTOR)/ADURL
ADSIMDETECTOR=$(AREA_DETECTOR)/ADSimDetector
ADMAR345=$(AREA_DETECTOR)/ADmar345
ADGENICAM=$(AREA_DETECTOR)/ADGenICam
ADPIXIRAD=$(AREA_DETECTOR)/ADPixirad

#
# complex ones that need custom makefile code to work in static modes
# (to resolve support libs that are still *.so and not *.a)
#

ADARAVIS=$(AREA_DETECTOR)/ADAravis
ADVIMBA=$(AREA_DETECTOR)/ADVimba
ADPROSILICA=$(AREA_DETECTOR)/ADProsilica
ADPILATUS=$(AREA_DETECTOR)/ADPilatus
ADEIGER=$(AREA_DETECTOR)/ADEiger

#RHEL8 Only
ADSPINNAKER=$(AREA_DETECTOR)/ADSpinnaker

####################################################################################################

#ADPointGrey does not play well on computers with legacy udev rules in play
#Enable at your own risk !!!!!!!!!!!!!!!!!!!
#ADPOINTGREY=$(AREA_DETECTOR)/ADPointGrey

#neither does Andor, conflicts in some way that generates unreal #'s of lost frames
#ADANDOR=$(AREA_DETECTOR)/ADAndor


And everything that is normally built-in via the standard XXX depoyment, which is most of synApps, also is available.

Since not all AD's play well with each other, also just building the default AD only binaries. And this code could be tweaked in to in any custum AD plugins, or other support, as required. No actual code is built-in by default; it all comes via shared libraries, so that if we patch APSshare, everyone using this sort of AD aware xxx would also get those changes on next restart.

Screen paths are obtained from the envPaths variables, so should track all changes.

Also potentially uses a patch version of caQtDM that correctly parses adl files into ui files at run time, so only 1 set of screen sources are required.

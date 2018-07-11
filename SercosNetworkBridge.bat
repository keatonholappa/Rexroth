@echo off
Goto :endComment
	***************************************************************************************************************************
	            ____   ____   _____  ________   __        ____   _______   __  ____   ____   ________   __
	          /  __  )/   __  \/  ___//     ____/  /  /  /       /  __  \/   ____/   \/  / /   __  \/  __   \/_     __/   /  /   /
	         / __   /   /   /  /\__  \/     /      /   /_/  /       /  /_/   /   __/    \     /  /  /_/   /   /  /   /  /   /   /   /_/   / 
	       /  /_/  /   / _/  /___/  /     /___/   __   /       /  _,  _/   /___  /       \/   _, _/   /_/    /  /   /   /   __   /
	     /_____/\____//____/ \______/ __/ /_/        /_/   \_/_____/ /__/ \_/_/   \_\\_____/  /__/   /__/  /_/   

	***************************************************************************************************************************
	Bosch Rexroth Corporation
	2315 City Line Rd. Bethlehem, PA 18017
	Author: Keaton Holappa
	Date: 7/11/2018
	   
	ATTENTION! This script may need to be run as an administrator to operate correctly!
	   
	This batch file allows a user to connect to a device (or devices) on an isolated Sercos III
	network through an MLC's (IndraControl L or XM) internal routing. I.e. it is possible to 
	connect to a Sercos device AND an MLC by plugging a single Ethernet cable into the MLC's engineering  
	port, or a switch connected to this port. The IP address of the computer running this script, and 
	connecting to these devices must have an IP address assigned to it, which is on the same network 
	as the engineering port of the MLC.

	This script uses the subnets of the Sercos and MLC (Engineering port) networks,
	as well as the IP address of the MLC. All of these values must be known.
	***********************************************************************

:endComment

   rem | Hardcode the subnet masks for the Sercos and MLC Engineering networks. These can only be changed by editing this file!
   set sercosSubnet=172.31.0.0
   set mlcSubnet=255.255.0.0

   rem | create the two possible commands, temporarily or permanently add the route
   set tempAdd=route add %sercosSubnet% mask %mlcSubnet%
   set permAdd=route -p add %sercosSubnet% mask %mlcSubnet%
   
   rem | *********************************************************
   rem | This begins the user interaction with the scipt
   echo This script allows you to connect to a Sercos III network via an MLC Engineering Network.
   rem | print to the user the hardcoded values of the Sercos and MLC Engineering Subnets
   echo Sercos Subnet is %sercosSubnet%and MLC Subnet is %mlcSubnet%. To change these, you must edit this batch file.
   echo This script may need to be run in administrator mode.
   
   :ScriptStart
   echo ********************************************************
   choice /m "Do you want to permenantly add this route to the settings of the PC? "
   IF "%errorlevel%" == "2" (
	set commandString=%tempAdd%
	Goto :Continue
   )

   choice /m "This is not recommended for non-experts. Are you sure you want to permanently add this route?"
   IF "%errorlevel%" == "1" (
	set commandString=%permAdd%
   ) ELSE (
	set commandString=%tempAdd%
   )

   rem | ask the user to enter the IP address of the MLC
   :Continue
   echo ********************************************************
   set /p ip="Enter IP Address of MLC: "

  set fullCommandString=%commandString% %ip%

   rem *********************************************************
   rem Determine if the entered IP address is a valid IP
   call :validateIP %ip% ret 
   rem echo %ip% : return value : !ret!

   rem call with or without variable to get errorlevel
   call :validateIP %ip% is valid || echo Input "%ip%" is an invalid IP Address. Please enter a value in the IPv4 form XXX.xxx.XXX.xxx
   
   rem If ret is 1 the IP is invalid. User must re-enter an IP.
   IF "%ret%" == "1" (
		Goto :Continue
   )
   rem *********************************************************

   rem | run the routing command, and formulate an output for the user
   for /f "delims=" %%i in ('%fullCommandString%') do set output=%%i

   
   IF "%output%"=="The requested operation requires elevation." (
		echo You must run this script in administrator mode
   )
   IF "%output%"==" OK!" (
		echo Success! It is now possible to connect to the %sercosSubnet% subnet through the MLC at %ip%.
   )
	
   echo Please press any key to terminate the script.
   pause >nul   
   
   rem *************************************************************************
   rem FUNCTIONS
   rem *************************************************************************   
   :validateIP ipAddress [returnVariable]
    rem prepare environment
    setlocal 

    rem asume failure in tests : 0=pass 1=fail : same for errorlevel
    set "_return=1"

    rem test if address conforms to ip address structure
    echo %~1^| findstr /b /e /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul

    rem if it conforms to structure, test each octet for rage values
    if not errorlevel 1 for /f "tokens=1-4 delims=." %%a in ("%~1") do (
        if %%a gtr 0 if %%a lss 255 if %%b leq 255 if %%c leq 255 if %%d gtr 0 if %%d leq 254 set "_return=0"
    )

	:endValidateIP
    rem clean and return data/errorlevel to caller
    endlocal & ( if not "%~2"=="" set "%~2=%_return%" ) & exit /b %_return%
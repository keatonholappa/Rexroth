@echo off
Goto :endComment	

	***************************************************************************************************************************

	Bosch Rexroth Corporation
	2315 City Line Rd. Bethlehem, PA 18017
	Author: Keaton Holappa
	Date: 3/14/2019
	   
	ATTENTION! This script needs to be run as an administrator to run!
	   
	This batch file allows a user to connect to a device (or devices) on an isolated Sercos III
	network through an MLC's (IndraControl L or XM) internal routing. I.e. it is possible to 
	connect to a Sercos device AND an MLC by plugging a single Ethernet cable into the MLC's engineering  
	port, or a switch connected to this port. The IP address of the computer running this script, and 
	connecting to these devices must have an IP address assigned to it, which is on the same network 
	as the engineering port of the MLC.

	This script uses the subnets of the Sercos and MLC (Engineering port) networks,
	as well as the IP address of the MLC. All of these values must be known.
	***************************************************************************************************************************

:endComment

   rem | Set the default subnet masks for the Sercos and MLC Engineering networks.
   set defSercosSubnet=172.31.0.0
   set defMlcSubnet=255.255.0.0
   
   rem | *********************************************************
   rem | This begins the user interaction with the scipt
   echo This script allows you to connect to a Sercos III network via an MLC Engineering Network.
   rem | print to the user the default values of the Sercos and MLC Engineering Subnets
   echo The default Sercos Subnet is %defSercosSubnet% and MLC Subnet is %defMlcSubnet%.
   
   :ScriptStart
   rem | Check if the user has run the program in Admin mode
   net session >nul 2>&1
   IF NOT %errorLevel% == 0 (
		echo ********************************************************
		echo You must run this script in Administrator mode
		Goto :ScriptEnd
	)

   echo ********************************************************
   choice /m "Do you want to use the default Sercos III subnet settings?"
   IF %errorlevel% == 2 (
   
		setlocal enabledelayedexpansion
	
		:SetSubnets
		rem | re-write the default subnet values
		set /p sercosSubnet="Enter the Subnet for your Sercos III Network: "
		call :validateSubnet !sercosSubnet! ret
		call :validateSubnet !sercosSubnet! is valid || echo Input "!sercosSubnet!" was entered in an invalid format. Please enter a value in the IPv4 form XXX.xxx.XXX.xxx
		rem | If ret is not 0 the Sercos Subnet is invalid. User must re-enter.
		IF NOT "!ret!" == "0" (
			Goto :SetSubnets
		)

		set /p mlcSubnet="Enter Subnet for MLC Network: "
		call :validateSubnet !mlcSubnet! ret
		call :validateSubnet !mlcSubnet! is valid || echo Input %mlcSubnet% was entered in an invalid format. Please enter a value in the IPv4 form XXX.xxx.XXX.xxx

		rem | If ret is not 0 the MLC Subnet is invalid. User must re-enter.
		IF NOT "!ret!" == "0" (
			Goto :SetSubnets
		) 
	) ELSE (
		set sercosSubnet=%defSercosSubnet%
		set mlcSubnet=%defMlcSubnet%
	)

   rem | First, add the route command
   set commandString=route add %sercosSubnet% mask %mlcSubnet%

   :Continue
   rem | ask the user to enter the IP address of the MLC
   echo ********************************************************
   set /p ip="Enter IP Address of MLC: "

   rem *********************************************************
   rem | Determine if the entered IP address is a valid IP
   call :validateIP %ip% ret
   call :validateIP %ip% is valid || echo Input "%ip%" is an invalid IP Address. Please enter a value in the IPv4 form XXX.xxx.XXX.xxx

   rem | If ret is not 0 the IP is invalid or not entered correctly. User must re-enter an IP.
   IF NOT "%ret%" == "0" (
	Goto :Continue
   )
   rem *********************************************************

   rem | run the routing command, and formulate an output for the user
   set fullCommandString=%commandString% %ip%
   for /f "delims=" %%i in ('%fullCommandString%') do set output=%%i

   
   IF "%output%"=="The requested operation requires elevation." (
	echo You must run this script in administrator mode
   )
   IF "%output%"==" OK!" (
	echo Success! It is now possible to connect to the %sercosSubnet% subnet through the MLC at %ip%.
   )

   :ScriptEnd
   echo Please press any key to terminate the script.
   pause >nul   
   
   rem *************************************************************************
   rem FUNCTIONS
   rem *************************************************************************   
   :validateIP ipAddress [returnVariable]
   rem | Prepare environment
   setlocal 
	
   rem | Assume failure in tests : 0=pass 1=fail : same for errorlevel
   set "_return=1"

   rem | Test if address conforms to ip address structure
   echo %~1^| findstr /b /e /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul

   rem | If it conforms to structure, test each octet for rage values
   if not errorlevel 1 for /f "tokens=1-4 delims=." %%a in ("%~1") do (
        if %%a gtr 0 if %%a lss 255 if %%b leq 255 if %%c leq 255 if %%d gtr 0 if %%d leq 254 set "_return=0"
   )
   
   rem | Clean and return data/errorlevel to caller
   endlocal & ( if not "%~2"=="" set "%~2=%_return%" ) & exit /b %_return%
   
   :endValidateIP

   :validateSubnet subnetMask [returnVariable]
   rem | Prepare environment
   setlocal 

   rem | Assume failure in tests : 0=pass 1=fail : same for errorlevel
   set "_return=1"

   rem | Test if address conforms to ip address structure
   echo %~1^| findstr /b /e /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul

   rem | If it conforms to structure, test each octet for rage values
   if not errorlevel 1 for /f "tokens=1-4 delims=." %%a in ("%~1") do (
        if %%a geq 0 if %%a leq 255 if %%b geq 0 if %%b leq 255 if %%c geq 0 if %%c leq 255 if %%d geq 0 if %%d leq 255 set "_return=0"
   )
   
   rem | Clean and return data/errorlevel to caller
   endlocal & ( if not "%~2"=="" set "%~2=%_return%" ) & exit /b %_return%

   :endValidateSubnet
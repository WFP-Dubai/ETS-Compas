:: Starting...
@echo off

if [%1]==[] (
	echo Please enter the Compas Station as first parameter
	echo Aborting...
	goto:eof
)

if [%2]==[] (
	echo Please enter the timestamp using format YYYYMMDD
	echo Aborting...
	goto:eof
)

set STATION=%1
set TIMESTAMP=%2

echo Station is: %STATION%
echo Timestamp is: %TIMESTAMP%

@echo on

call 1_full_export.bat %1 %2
pause

call 2_create_testq.bat %1
pause

call 3_import.bat %1 %2
pause

call 4_fix.bat %1 
pause

call 5_create_testq_newobjs.bat %1
pause

call 6_create_testw_syn.bat %1

echo End.
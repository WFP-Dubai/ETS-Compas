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

echo STEP 1: Export
call 1_full_export.bat %1 %2
pause

echo STEP 2: Create TESTQ
call 2_create_testq.bat %1
pause

echo STEP 3: Import
call 3_import.bat %1 %2
pause

echo STEP 4: Fix import
call 4_fix.bat %1 
pause

echo STEP 5: Create new objects
call 5_create_testq_newobjs.bat %1
pause

echo STEP 6: Create synonyms
call 6_create_testw_syn.bat %1

echo End.
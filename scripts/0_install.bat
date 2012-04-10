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

if [%3]==[] (
	set STEP=1
) else (
	set STEP=%3
)

set STATION=%1
set TIMESTAMP=%2
set /p VERSION=<..\VERSION

echo Installing ETS-COMPAS version: %VERSION%
echo Station is: %STATION%
echo Timestamp is: %TIMESTAMP%
echo Requested starting step: %STEP%

@echo on

@if 1 geq %STEP% (
	echo STEP 1: Export
	call 1_full_export.bat %STATION% %TIMESTAMP%
	pause
)

@if 2 geq %STEP% (
	echo STEP 2: Create TESTQ
	call 2_create_testq.bat %STATION%
	pause
)

@if 3 geq %STEP% (
	echo STEP 3: Import
	call 3_import.bat %STATION% %TIMESTAMP%
	pause
)

@if 4 geq %STEP% (
	echo STEP 4: Fix import
	call 4_fix.bat %STATION% 
	pause
)

@if 5 geq %STEP% (
	echo STEP 5: Create new objects
	call 5_create_testq_newobjs.bat %STATION% %VERSION%
	pause
)

@if 6 geq %STEP% (
	echo STEP 6: Create synonyms
	call 6_create_testw_syn.bat %STATION%
)

echo End.
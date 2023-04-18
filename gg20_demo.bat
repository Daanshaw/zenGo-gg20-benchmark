@echo off
echo Creating necessary directories...
mkdir target
cd target
mkdir release
cd release
mkdir examples
cd examples

echo Starting SM server...
start gg20_sm_manager.exe

echo Generating keys...
gg20_keygen.exe -t 1 -n 3 -i 1 --output local-share1.json
gg20_keygen.exe -t 1 -n 3 -i 2 --output local-share2.json
gg20_keygen.exe -t 1 -n 3 -i 3 --output local-share3.json

echo Signing message with 2 parties...
gg20_signing.exe -p 1,2 -d "hello" -l local-share1.json
gg20_signing.exe -p 1,2 -d "hello" -l local-share2.json

echo Finished signing.
pause

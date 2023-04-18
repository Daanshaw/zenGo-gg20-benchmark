#!/bin/bash

SECONDS=0

echo "Creating necessary directories..."


echo "Starting SM server..."
./gg20_sm_manager &
sm_pid=$!

# Adding a delay to ensure SM server is ready for connections
sleep 5

echo "Generating keys..."
./gg20_keygen -t 1 -n 3 -i 1 --output local-share1.json &
pid1=$!
./gg20_keygen -t 1 -n 3 -i 2 --output local-share2.json &
pid2=$!
./gg20_keygen -t 1 -n 3 -i 3 --output local-share3.json &
pid3=$!

wait $pid1
wait $pid2
wait $pid3

echo "Signing message with 2 parties..."
./gg20_signing -p 1,2 -d "hello" -l local-share1.json &
pid4=$!
wait $pid4
./gg20_signing -p 1,2 -d "hello" -l local-share2.json &
pid5=$!
wait $pid5

echo "Finished signing."

echo "Terminating SM server..."
kill $sm_pid

elapsed_time=$SECONDS

echo "Elapsed time: $elapsed_time seconds"

echo "Press Enter to close the terminal..."
read

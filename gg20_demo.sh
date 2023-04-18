#!/bin/bash

SECONDS=0

echo "Creating necessary directories..."
mkdir -p target/release/examples
cd target/release/examples

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

gnome-terminal -- bash -c "cd target/release/examples; ./gg20_signing -p 1,2 -d 'hello' -l local-share1.json; echo 'Press Enter to close the terminal...'; read"
gnome-terminal -- bash -c "cd target/release/examples; ./gg20_signing -p 1,2 -d 'hello' -l local-share2.json; echo 'Press Enter to close the terminal...'; read"

echo "Finished signing."

echo "Terminating SM server..."
kill $sm_pid

elapsed_time=$SECONDS

echo "Elapsed time: $elapsed_time seconds"

echo "Press Enter to close the terminal..."
read

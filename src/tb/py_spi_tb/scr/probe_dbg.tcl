database -open waves -into waves.shm -default
probe -create fpgnix_tb -depth all -tasks -functions -uvm -packed 16k -unpacked 64k -all -dynamic -memories -database waves
run 1000000000
# run
exit



# netspeed
Bash script for monitoring bandwidth usage.


usage: netspeed.sh [-b bits] [-c count] [-f <k, M, G> prefix ]
 		   [-i <seconds> interval] [-I <interface name> interface]
example:
	./netspeed.sh -f k		      	   #average speed in kB/s on all interfaces
	./netspeed.sh -b -f M -c 0 -I eth0 -i 2    #average speed in Mb/s every 2 seconds unti user-interrupt for eth0

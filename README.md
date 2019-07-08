# Netspeed
Bash script for measuring current bandwidth usage without root access

usage: 
	
	netspeed.sh [-b bits] [-c count] [-f <k, M, G> prefix ]
 		    [-i <seconds> interval] [-I <interface name> interface]
	
example:
	
	./netspeed.sh -f k		      	   #speed in kB/s on all interfaces
	./netspeed.sh -b -f M -c 0 -I eth0 -i 2    #speed in Mb/s every 2 seconds until user-interrupt for eth0

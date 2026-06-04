#include <stdio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <pthread.h>

//#define DEBUG
#ifdef DEBUG
#define DBG fprintf(stderr, "\n(io_server.c) enter %s\n",__func__);
#else
#define DBG
#endif

//reference: www.geeksforgeeks.org/socket-programming-cc/
#define FIFO_SIZE (128)
int g_server;
int g_socket;
struct sockaddr_in g_address;
int g_addrlen = sizeof(g_address);
char g_fifo[FIFO_SIZE];
unsigned char g_wrptr = 0;
unsigned char g_rdptr = 0;

int cnt1 = 0;
int cnt2 = 0;
void* socket_read(void* vargp) {DBG
    while (1) {
        char c;
        int status;
        c = 0;
        status = read(g_socket, &c, sizeof(c));
        cnt1++;
        
        if (status==1) {
            g_fifo[g_wrptr%FIFO_SIZE] = c;
            g_wrptr++;

            while ((unsigned char)(g_wrptr-g_rdptr)>=(unsigned char)(FIFO_SIZE));
            //while ((g_wrptr)!=g_rdptr);
        } else {
            volatile int i;
            fprintf(stderr, "\n(io_server.c) connection dropped. waiting for new connection\n");
            wait_for_connection();
        }
    }
}
int io_get(char* message) {DBG
   if (g_wrptr==g_rdptr)
       return 0;

   *message = g_fifo[g_rdptr%FIFO_SIZE];
   g_rdptr++;

   cnt2++;

   return 1;
}

void wait_for_connection() {DBG
    if((g_socket = accept(g_server, (struct sockaddr *)&g_address, (socklen_t*)&g_addrlen)) < 0)
        fprintf(stderr, "\n\n(io_server.c) accept error\n\n");
}

int io_init(int client_option) {DBG
   int opt = 1;
   char command[100];
   if((g_server = socket(AF_INET, SOCK_STREAM, 0)) == 0) 
      fprintf(stderr, "\n\n(io_server.c) socket error\n\n");

   if (setsockopt(g_server, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT,  &opt, sizeof(opt)))
      fprintf(stderr, "\n\n(io_server.c) setsockopt error\n\n");
   
   g_address.sin_family = AF_INET;
   g_address.sin_addr.s_addr = INADDR_ANY;
   g_address.sin_port = 0; 
   
   if(bind(g_server, (struct sockaddr *)&g_address, sizeof(g_address)) < 0) 
      fprintf(stderr, "\n\n(io_server.c) bind error\n\n");
   
   if(listen(g_server, 2) < 0)
       fprintf(stderr, "\n\n(io_server.c) listen error\n\n");
     
   socklen_t len = sizeof(g_address);
   if(getsockname(g_server, (struct sockaddr *)&g_address, &len) == -1)
       fprintf(stderr, "\n\n(io_server.c) name error\n\n");
   
   char hostname[100];
   gethostname(hostname, 100);
   
   switch (client_option) {
       case 0:
           fprintf(stderr, "\n(io_server.c) server running (%s:%d), waiting for client to connect\n", hostname, ntohs(g_address.sin_port));
           fprintf(stderr, "setenv SIM_HOST %s\n", hostname);
           fprintf(stderr, "setenv SIM_PORT %d\n", ntohs(g_address.sin_port));
           break;
       case 1:
           sprintf(command, "xterm -hold -e 'python3 $PULP_ENV/src/tb/io_client.py %d telnet' &", ntohs(g_address.sin_port));
           system(command); 
           break;
       case 2:
           sprintf(command, "xterm -hold -e 'python3 -i $PULP_ENV/src/tb/io_client.py %d pyshell' &", ntohs(g_address.sin_port));
           system(command); 
           break;
       case 3:
           sprintf(command, "xterm -hold -e 'python3 $PULP_ENV/src/tb/io_client.py %d txonly' &", ntohs(g_address.sin_port));
           system(command); 
           break;
       case 4:
           sprintf(command, "xterm -hold -e 'python3 -i $PULP_ENV/src/tb/io_client.py %d jtag' &", ntohs(g_address.sin_port));
           system(command); 
           break;
       default:
           fprintf(stderr, "\n\n(io_server.c) unknown client_option\n\n");
           exit(1);
   }

   wait_for_connection();
  
   pthread_t tid; 
   pthread_create(&tid, NULL, socket_read, NULL);
   return 1;
}

int io_put(char output) {DBG
   return send(g_socket, &output, sizeof(output), 0);
}


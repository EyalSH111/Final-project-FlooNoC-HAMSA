import r2d2

lb = r2d2.I_Loopback()

send = ''
for i in range(1000):
    send += chr(ord('0')+(i%10))

lb.puts(send)
recv = lb.gets(1000)

if recv != send:
    print('send: '+send)
    print('recv: '+recv)
    raise Exception("Test Failed (1)")

for i in range(100):
    lb.puts(send[i*10:i*10+10])

recv = ''
for i in range(50):
    recv += lb.gets(20)

if recv != send:
    print('send: '+send)
    print('recv: '+recv)
    raise Exception("Test Failed (2)")

print('Test Passed')

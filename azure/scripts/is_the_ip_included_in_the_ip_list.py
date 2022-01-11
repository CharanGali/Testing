import sys
import ipaddress

def main(my_ip, sen_ip_list):
    for sen_ip in sen_ip_list:
        if ipaddress.ip_address(my_ip) in ipaddress.ip_network(sen_ip):
            sys.stdout.write("true")
            sys.exit(0)

    sys.stdout.write("false")
    sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("invalid input")
        sys.exit(1)

    my_ip = sys.argv[1]
    sen_ip_list = sys.argv[2:]
    main(my_ip, sen_ip_list)

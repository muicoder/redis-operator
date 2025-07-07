package util

import "net"

func GetLocalIP() (string, error) {
	conn, err := net.Dial("udp", "1.2.4.8:80")
	if err != nil {
		return "", err
	}
	defer conn.Close()
	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String(), nil
}

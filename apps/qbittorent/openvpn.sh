apit install openvpn
scp norway.ovpn
mv ~/norway.ovpn /etc/openvpn/norway.conf
sed 's/auth-user-pass/auth-user-pass /etc/openvpn/passwd'
echo USERNAME >> /etc/openvpn/passwd
echo PASSWORD >> /etc/openvpn/passwd
chmod 400 /etc/openvpn/passwd
chmod 400 /etc/openvpn/*.conf
sudo systemctl start openvpn@norway
sudo systemctl enable openvpn@norway



# ## You need to add this in the container's .conf file in the host's /etc/pve/lxc/<container_id>.conf
# lxc.cgroup2.devices.allow: c 10:200 rwm
# lxc.mount.entry: /dev/net dev/net none bind,create=dir

# ensure weh ave the right config
curl ipinfo.io

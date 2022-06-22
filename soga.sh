#!/binstall

# bảng điều khiển
red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}

# Xác định hệ thống và xác định các phụ thuộc cài đặt hệ thống
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
	SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
	[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "VPS không tương thích, vui lòng sử dụng hệ điều hành chính" && exit 1

archAffix() {
	case "$(uname -m)" in
  x86_64 | x64 | amd64) return 0 ;;
	aarch64 | arm64) return 0 ;;
	*) red "Cầu hình CPU không được hỗ trợ, tập lệnh sắp thoát!" ;;
	esac

	return 0
}

install() {
	install_soga
	clear
	makeConfig
}

install_soga() {
	[[ -z $(type -P curl) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} curl
	[[ -z $(type -P socat) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} socat
	bash <(curl -Ls https://raw.githubusercontent.com/sprov065/soga/master/install.sh)
}

makeConfig() {
    echo "---------------"

	read -p "Loại máy chủ, v2ray, trojan :" ssServer 
	echo "---------------"
	read -p "Số node ID :" ssNodeID
	echo "---------------"
	read -p "Giới hạn số thiết bị, nếu không muốn giới hạn hãy nhập 0 :" makeLimitdevice
	echo "---------------"
	read -p "CertMode:" CertMode
	echo "---------------"
        read -p "CertDomain:" CertDomain
	echo "---------------"

	rm -f /etc/soga/soga.conf
	if [[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
		curl https://get.acme.sh | sh -s email=script@github.com
		source ~/.bashrc
		bash ~/.acme.sh/acme.sh --upgrade --auto-upgrade
	fi
         cat <<EOF >/etc/soga/soga.conf
# 基础配置
type=v2board
server_type=$ssServer
node_id=$ssNodeID
soga_key=

# webapi 或 db 对接任选一个
api=webapi

# webapi 对接信息
webapi_url=https://5ggiare.com
webapi_key=4ggiare4ggiare4ggiare

# db 对接信息
db_host=db.domain.com
db_port=3306
db_name=
db_user=
db_password=

# 手动证书配置
cert_file=/etc/soga/server.pem
key_file=/etc/soga/privkey.pem

# 自动证书配置
cert_mode=$CertMode
cert_domain=$CertDomain
cert_key_length=ec-256
dns_provider=

# dns 配置
default_dns=8.8.8.8,1.1.1.1
dns_cache_time=10
dns_strategy=ipv4_first

# v2ray 特殊配置
v2ray_reduce_memory=false
vless=false
vless_flow=

# proxy protocol 中转配置
proxy_protocol=false

# 全局限制用户 IP 数配置
redis_enable=false
redis_addr=
redis_password=
redis_db=0
conn_limit_expiry=60

# 其它杂项
user_conn_limit=$makeLimitdevice
user_speed_limit=0
node_speed_limit=0
check_interval=60
force_close_ssl=false
forbidden_bit_torrent=true
log_level=info

# 更多配置项如有需要自行添加
EOF
        wget https://raw.githubusercontent.com/thiensu99/key_pem/main/server.pem -O /etc/soga/server.pem
        wget https://raw.githubusercontent.com/thiensu99/key_pem/main/privkey.pem -O /etc/soga/privkey.pem
	soga start
	green "Đã cài đặt và cập nhật soga với bảng điều khiển thành công！"
	exit 1
}

install

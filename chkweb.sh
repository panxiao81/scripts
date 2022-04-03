#!/bin/bash

# TODO: A true daemon program
# Run with nohup /scripts/ChkWeb.sh
# Version 0.1 Initial
# Copyright Pan Xiao MIT License

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

IP="172.16.100.201"

Check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        echo "Please run as root"
        exit 1
    fi
}

Help() {
    echo "`basename $0`, Monitoring the Backend web server."
    echo "Usage: `basename $0` [recover]"
    echo "Example:"
    echo -e "\tRunning in back"
    echo -e "\t\t nohup $0 &"
    echo -e "\tRecover the nginx configuration"
    echo -e "\t\t $0 recover"
}


Monitoring() {
    Check_root
    while true; do
        curl --connection-timeout 5 --fail -L $IP
        if [ $? -ne 0 ]; then
            for i in $(seq 3); do
                curl --connection-timeout 5 --fail -L $IP
                if [ $? -eq 0 ]; then
                    continue 2
                fi
                sleep 5
            done
            Change_webpage
        fi
        sleep 5
    done
}


Change_webpage() {
    mv /etc/nginx/conf.d/proxy.conf /etc/nginx/conf.d/proxy.conf.bak
    mv /etc/nginx/conf.d/default.conf.bak /etc/nginx/conf.d/default.conf
    echo "网站无法访问，请稍后再试" > /usr/share/nginx/html/index.html
    systemctl restart nginx
}


Recover() {
    Check_root
    mv /etc/nginx/conf.d/ssl.conf.bak /etc/nginx/conf.d/ssl.conf
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
    rm -f /usr/share/nginx/html/index.html
    systemctl restart nginx
}


if [ $# -eq 0 ]; then
    Monitoring
fi

if [ $# -gt 0 ]; then
    case "$1" in
        -h|--help )
            Help
            ;;
        recover )
            Recover
            ;;
        *)
            echo "Invaild arguments $1"
            Help
            ;;
    esac
fi

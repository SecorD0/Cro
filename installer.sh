#!/bin/bash
# Default variables
cro_moniker=$cro_moniker
cro_wallet_name=$cro_wallet_name
# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs Cro node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help               show the help page"
		echo -e "  -m, --moniker MONIKER    node MONIKER, manual input, if not set (default is \"${C_LGn}${cro_moniker}${RES}\")"
		echo -e "  -wn, --wallet-name NAME  wallet NAME, manual input, if not set (default is \"${C_LGn}${cro_wallet_name}${RES}\")"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Cro/blob/main/installer.sh - script URL"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0
		;;
	-m*|--moniker*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		cro_moniker=`option_value "$1"`
		shift
		;;
	-wn*|--wallet-name*)
		if ! grep -q "=" <<< "$1"; then shift; fi
		cro_wallet_name=`option_value "$1"`
		shift
		;;
	*|--)
		break
		;;
	esac
done
# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
# Actions
sudo apt install wget -y
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
printf_n "The guide of ${C_LGn}https://t.me/mzonder${RES} was used: ${Bl_R}https://mzonder.notion.site/mzonder/CRO-Relayer-d84e481dbf484d59b5595075d36ba383${RES}\n"
if [ ! -n "$cro_moniker" ]; then
	printf "${C_LGn}Enter a node moniker:${RES} "
	read cro_moniker
fi
printf_n "Your node moniker: ${C_LGn}${cro_moniker}${RES}"
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n cro_moniker -v "$cro_moniker"
if [ ! -n "$cro_wallet_name" ]; then
	printf "${C_LGn}Enter a wallet name:${RES} "
	read cro_wallet_name
fi
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n cro_wallet_name -v "$cro_wallet_name"
printf_n "Your wallet name: ${C_LGn}${cro_wallet_name}${RES}"
sudo apt install jq git build-essential pkg-config libssl-dev -y
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/installers/golang.sh) --
printf_n "${C_LGn}Node installation...${RES}"
cd
wget https://github.com/crypto-org-chain/chain-main/releases/download/v3.1.0-croeseid/chain-main_3.1.0-croeseid_Linux_x86_64.tar.gz
sudo tar -zxvf chain-main_3.1.0-croeseid_Linux_x86_64.tar.gz
sudo rm -rf chain-main_3.1.0-croeseid_Linux_x86_64.tar.gz CHANGELOG.md LICENSE readme.md
sudo cp $HOME/bin/chain-maind /usr/local/bin/
chain-maind init "$cro_moniker" --chain-id testnet-croeseid-4
wget -qO $HOME/.chain-maind/config/genesis.json https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-4/genesis.json
sed -i.bak -e 's%minimum-gas-prices = ""%minimum-gas-prices = "0.025basetcro"%; '\
's%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:9095\"%; '\
's%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:9096\"%' $HOME/.chain-maind/config/app.toml
LATEST_HEIGHT=`curl -s https://testnet-croeseid-4.crypto.org:26657/block | jq -r .result.block.header.height`
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=`curl -s "https://testnet-croeseid-4.crypto.org:26657/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash`
sed -i.bak -e 's%^persistent_peers = ""%persistent_peers = "71d2a4727bf574d5d368c343e37edff00cd556b1@52.76.52.229:26656,8af7c92277f3edce58aa828cf1026cfa74fd6569@18.141.249.17:26656"%; '\
's%^create_empty_blocks_interval *=.*%create_empty_blocks_interval = "5s"%; '\
's%^timeout_commit *=.*%timeout_commit = "2s"%; '\
's%^enable *=.*%enable = true%; '\
's%^rpc_servers *=.*%rpc_servers = "https://testnet-croeseid-4.crypto.org:26657,https://testnet-croeseid-4.crypto.org:26657"%; '\
's%^trust_height *=.*%trust_height = '$BLOCK_HEIGHT'%; '\
's%^trust_hash *=.*%trust_hash = "'$TRUST_HASH'"%; '\
's%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:26668\"%; '\
's%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:26667\"%; '\
's%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:6065\"%; '\
's%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:26666\"%; '\
's%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":26670\"%' $HOME/.chain-maind/config/config.toml
sudo tee /etc/systemd/system/chain-maind.service > /dev/null <<EOF
[Unit]
Description=Chain-maind
After=network.target

[Service]
User=$USER
ExecStart=$(which chain-maind) start
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable chain-maind
sudo systemctl restart chain-maind
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n cro_log -v "sudo journalctl -f -n 100 -u chain-maind" -a
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n cro_node_info -v ". <(wget -qO- https://raw.githubusercontent.com/SecorD0/Cro/main/node_info.sh) -l RU 2> /dev/null" -a
printf_n
chain-maind keys add "$cro_wallet_name" --keyring-backend file

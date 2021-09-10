#!/bin/bash
sudo apt install wget -y
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
echo -e 'The guide of \e[40m\e[92mhttps://t.me/mzonder\e[0m was used: https://mzonder.notion.site/mzonder/CRO-Relayer-d84e481dbf484d59b5595075d36ba383\n'
if [ ! $cro_moniker ]; then
	echo -n -e '\e[40m\e[92mEnter a node moniker:\e[0m '
	read -r cro_moniker
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/insert_variable.sh) "cro_moniker" $cro_moniker
fi
echo -e "Your node name: \e[40m\e[92m$cro_moniker\e[0m\n"
if [ ! $cro_wallet_name ]; then
	echo -n -e '\e[40m\e[92mEnter a wallet name:\e[0m '
	read -r cro_wallet_name
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/insert_variable.sh) "cro_wallet_name" $cro_wallet_name
fi
echo -e "Your wallet name: \e[40m\e[92m$cro_wallet_name\e[0m\n"
sudo apt install jq git build-essential pkg-config libssl-dev -y
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/golang_installer.sh)
echo -e '\e[40m\e[92mNode installation...\e[0m'
cd
wget https://github.com/crypto-org-chain/chain-main/releases/download/v3.0.0-croeseid/chain-main_3.0.0-croeseid_Linux_x86_64.tar.gz
sudo tar -zxvf chain-main_3.0.0-croeseid_Linux_x86_64.tar.gz
sudo rm -rf chain-main_3.0.0-croeseid_Linux_x86_64.tar.gz CHANGELOG.md LICENSE readme.md
sudo cp $HOME/bin/chain-maind /usr/local/bin/
chain-maind init $cro_moniker --chain-id testnet-croeseid-4
wget -qO $HOME/.chain-maind/config/genesis.json https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-4/genesis.json
sed -i.bak -e 's%minimum-gas-prices = ""%minimum-gas-prices = "0.025basetcro"%; '\
's%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:9095\"%; '\
's%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:9096\"%' $HOME/.chain-maind/config/app.toml
LATEST_HEIGHT=$(curl -s https://testnet-croeseid-4.crypto.org:26657/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "https://testnet-croeseid-4.crypto.org:26657/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
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
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/insert_variable.sh) "cro_log" "sudo journalctl -f -n 100 -u chain-maind" true
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/insert_variable.sh) "cro_log" "sudo journalctl -f -n 100 -u chain-maind" true
chain-maind keys add $cro_wallet_name --keyring-backend file

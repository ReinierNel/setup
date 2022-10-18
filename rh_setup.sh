#!/usr/bin/bash

# versions
terraform="1.1.7"
gomplate="3.11.1"
glow="1.4.1"
slack="4.27.154"
path="/usr/local/bin/"

# handel input arguments
declare -A argList=()
for arg in "$@"
do
	case "$arg" in
		--*)
			option="$arg"
		;;
		*)
			value="$arg"
		;;
	esac

	argList["$option"]="$value"
done

# help message
function 1_help_msg {
cat << EOF

This script setups and install software needed for BMA Engineers

Usage: $0 [--option] [value]

Options:

--help				NONE							Shows this help screen
--list-func			NONE							List all availible functions
--only-run			function1,function2				Comma sepirated list of functions to run skip the rest

EOF
}

# update systems
function 2_update {
	sudo dnf update -y
}

# setup azure cli dnf repo
function 3_az_repo_prep {
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
	echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
}

# setup powerhsell
function 3_powershell_repo_prep {
	curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
}

# setup docker dnf repo
function 3_docker_repo_prep {
	sudo dnf remove -y docker \
	docker-client \
	docker-client-latest \
	docker-common \
	docker-latest \
	docker-latest-logrotate \
	docker-logrotate \
	docker-selinux \
	docker-engine-selinux \
	docker-engine

	sudo dnf install -y dnf-plugins-core

	sudo dnf config-manager \
    	--add-repo \
    	https://download.docker.com/linux/fedora/docker-ce.repo
}

# setup Fusion NonFree/Free repo
function 3_fusion_repo_prep {
	sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm
	sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
	sudo dnf update --refresh
}

# install all dnf packages at same time
function 4_install_packages {
	sudo dnf install -y \
	azure-cli \
	git \
	python3-pip \
	docker-ce \
	docker-ce-cli \
	containerd.io \
	docker-compose-plugin \
	jq \
	terminator \
	ShellCheck \
	libappindicator-gtk3 \
	liberation-fonts \
	akmod-nvidia \
	xorg-x11-drv-nvidia-cuda \
	keepassxc \
	gnome-tweak-tool \
	clamav \
	clamav-update \
	powershell \
	fzf \
	yamllint \
	xclip \
	speedtest-cli \
	wmctrl \
	xdotool \
	nmap \
	emacs \
	gridsite-clients \
	golang
}

# enable flatpack
function 4_prep_flatpack {
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function 5_install_gnome_extentions {
	flatpak install flathub org.gnome.Extensions
}

# kubectl
function 5_install_kubectl {
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	sudo mv kubectl "$path"
}

# kustomize
function 5_install_kustomize {
	curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
	sudo mv kustomize "$path"
}

# terraform
function 5_install_terraform {
	curl -L "https://releases.hashicorp.com/terraform/${terraform}/terraform_${terraform}_linux_amd64.zip" -o terraform.zip
	unzip terraform.zip
	chmod +x terraform
	sudo mv terraform "$path"
	rm terraform.zip
}

# vscode
function 5_install_vscode {
	curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" -o code.rpm
	sudo rpm -i code.rpm
	rm code.rpm
}

# argocd cli
function 5_install_argocd_cli {
	curl -LO "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
	chmod +x argocd-linux-amd64
	sudo mv argocd-linux-amd64 "$path"/argoci
}

# gomplate
function 5_install_gomplate {
	curl -LO "https://github.com/hairyhenderson/gomplate/releases/download/v$gomplate/gomplate_linux-amd64"
	chmod +x gomplate_linux-amd64
	sudo mv gomplate_linux-amd64 "$path"/gomplate
}

# helm
function 5_install_helm {
	curl -L "https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz" -o helm.tar.gz
	tar -zxf helm.tar.gz
	sudo mv linux-amd64/helm "$path"
	rm -r linux-amd64
	rm helm.tar.gz
}

# glow
function 5_install_glow {
	curl -LO "https://github.com/charmbracelet/glow/releases/download/v${glow}/glow_${glow}_linux_amd64.rpm"
	sudo rpm -i glow_1.4.1_linux_amd64.rpm
	rm glow_1.4.1_linux_amd64.rpm
}

# install slack
function 5_install_slack {
	curl -LO "https://downloads.slack-edge.com/releases/linux/${slack}/prod/x64/slack-${slack}-0.1.fc21.x86_64.rpm"
	sudo rpm -i "slack-${slack}-0.1.fc21.x86_64.rpm"
	rm "slack-${slack}-0.1.fc21.x86_64.rpm"
}

# install chrome
function 5_install_chrome {
	curl -LO "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
	sudo rpm -i google-chrome-stable_current_x86_64.rpm
	rm google-chrome-stable_current_x86_64.rpm
}

# install lens
function 5_install_lens {
	curl -L "https://api.k8slens.dev/binaries/Lens-5.5.4-latest.20220609.2.x86_64.rpm" -o lens.rpm
	sudo rpm -i lens.rpm
	rm lens.rpm
}

function 5_install_kubectx {
	sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
	sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
	sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

	git clone https://github.com/ahmetb/kubectx.git ~/.kubectx
	COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
	sudo ln -sf ~/.kubectx/completion/kubens.bash $COMPDIR/kubens
	sudo ln -sf ~/.kubectx/completion/kubectx.bash $COMPDIR/kubectx
cat << EOF >> ~/.bashrc

#kubectx and kubens
export PATH=~/.kubectx:\$PATH
EOF
}

# update clamav
function 6_update_clamav {
	sudo freshclam
}

# setup golang path
function 6_gopath {
	mkdir -p $HOME/go
	echo 'export GOPATH=$HOME/go' >> $HOME/.bashrc
	source $HOME/.bashrc
	go env GOPATH
}

mapfile -t FUNC_LIST < <(declare -F)

function main {

	if [ "${#argList[@]}" -eq 0 ]
	then
		for func in "${FUNC_LIST[@]}"
		do
			if ! [ "$func" = "declare -fx which" ]
			then
				func_name=$(echo "$func" | cut -d " " -f 3)

				if ! [ "$func_name" = "1_help_msg" ]
				then
					$func_name
				fi
			fi
		done
	else
		for selected in "${!argList[@]}"
		do
			case "$selected" in
				--help)
					1_help_msg
				;;
				--list-func)
					for func in "${FUNC_LIST[@]}"
					do
						if ! [ "$func" = "declare -fx which" ]
						then
							echo "$func" | cut -d " " -f 3
						fi
					done
				;;
				--only-run)
					IFS=',' read -r -a func_list <<< "${argList[$selected]}"
					for funcs in "${func_list[@]}"
					do
						echo "running specific function $funcs"
						$funcs
					done
				;;
			esac
		done
	fi
}

main

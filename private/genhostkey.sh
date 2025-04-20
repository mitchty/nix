host="${1?need a hostname}"

install -dm755 ${host}

cd ${host} || exit 126

for typ in ed25519 ecdsa; do
  ssh-keygen -t "${typ}" -f ssh_host_${typ}_key -N '' -C 'private'
done

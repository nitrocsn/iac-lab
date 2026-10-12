[lab]
%{ for vm in vms ~}
${vm.nom} ansible_host=${vm.ip} ansible_user=admin ansible_python_interpreter=/usr/bin/python3
%{ endfor ~}

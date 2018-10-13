Vagrant.configure("2") do |config|
  config.vm.network "private_network", type: "dhcp"
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/app", type: "nfs"
end

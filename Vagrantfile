Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network :forwarded_port, guest: 80, host: 4567

  config.berkshelf.enabled = true

  VAGRANT_JSON = JSON.parse(Pathname(__FILE__).dirname.join('nodes', 'vagrant.json').read)

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["site-cookbooks", "cookbooks"]
    chef.roles_path = "roles"
    chef.data_bags_path = "data_bags"
    chef.provisioning_path = "/tmp/vagrant-chef"

    chef.run_list = VAGRANT_JSON.delete('run_list')
    chef.json = VAGRANT_JSON
  end

   config.vm.provider "virtualbox" do |v|
       v.memory = 2048
       v.cpus = 2
   end
end

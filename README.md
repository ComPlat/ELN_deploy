# ELN_deploy

This is a chef recipe to install Chemotion ELN to server
Rough list of commands to use
* apt-get install ruby
* gem install bundler
* bundle
* Important: edit user and passwords first!
* knife solo prepare <user>@<IP or domain>
* knife solo cook <user>@<IP or domain>
